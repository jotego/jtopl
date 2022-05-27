/* This file is part of JTOPL

    JTOPL program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-5-2022

*/

module jtopll_reg(
    input            rst,
    input            clk,
    input            cen,


    // PG
    output     [9:0] fnum_I,
    output     [2:0] block_I,
    // channel configuration
    output     [2:0] fb_I,


    output     [3:0] mul_II,  // frequency multiplier
    output     [1:0] ksl_IV,  // key shift level
    output           amen_IV,
    output           viben_I,
    // OP
    output     [1:0] wavsel_I,
    input            wave_mode,
    // EG
    output           keyon_I,
    output     [5:0] tl_IV,
    output           en_sus_I, // enable sustain
    output     [3:0] arate_I,  // attack  rate
    output     [3:0] drate_I,  // decay   rate
    output     [3:0] rrate_I,  // release rate
    output     [3:0] sl_I,     // sustain level
    output           ks_II,    // key scale
    output           con_I,

    output     [3:0] vol_I,    // channel volume

    input      [6:0] prog_addr,
    input      [7:0] prog_data,
    input            prog_we
);

localparam CH=9;

// Each group contains three channels
// and each subslot contains six operators
reg  [2:0] subslot;

reg [5:0] rhy_csr;
reg       rhy_oen;

`ifdef SIMULATION
// These signals need to operate during rst
// initial state is not relevant (or critical) in real life
// but we need a clear value during simulation
initial begin
    group   = 2'd0;
    subslot = 3'd0;
    slot    = 18'd1;
end
`endif

wire       match      = { group, subslot } == { sel_group, sel_sub};
wire [2:0] next_sub   = subslot==3'd5 ? 3'd0 : (subslot+3'd1);
wire [1:0] next_group = subslot==3'd5 ? (group==2'b10 ? 2'b00 : group+2'b1) : group;

reg  [63:0] patch[0:15]; // instrument memory
wire [ 3:0] inst_I;

// Fixed for OPLL, but free in OPL
assign fnum_I[9] = 0;

always @(posedge clk) begin
    if( prog_we )
        patch[ prog_addr[6:3] ][ prog_addr[2:0]*2 +:8 ] = prog_data;
end

assign { amen_I, viben_I, en_sus_I, ks_I, mul_I } = patch[ inst_I ];
assign { amen_I, viben_I, en_sus_I, ks_I, mul_I } = patch[ inst_I ];

// Memory for CH registers
localparam KONW   =  1,
           FNUMW  = 10,
           BLOCKW =  3,
           FBW    =  3,
           INSTW  =  4,
           VOLW   =  4;
localparam CHCSRW = KONW+FNUMW+BLOCKW+FBW+INSTW+VOLW;

wire [CHCSRW-1:0] chcfg0_out, chcfg1_out, chcfg2_out;
reg  [CHCSRW-1:0] chcfg, chcfg0_in, chcfg1_in, chcfg2_in;
wire [CHCSRW-1:0] chcfg_inmux;
wire              sus_en, keyon_csr, con_csr;
wire              disable_con;

assign chcfg_inmux = {
    up_fnumhi_ch   ? din[5:0] : { sus_en, keyon_csr, block_I, fnum_I[8] },
    up_fnumlo_ch   ? din      : fnum_I[7:0],
    up_inst_vol_ch ? din      : { inst_I, vol_I }
};

assign disable_con = rhy_oen && !slot[12] && !slot[13];
assign con_I       = rhy_en && disable_con;

always @(*) begin
    case( group )
        default: chcfg = chcfg0_out;
        2'd1: chcfg = chcfg1_out;
        2'd2: chcfg = chcfg2_out;
    endcase
    chcfg0_in = group==2'b00 ? chcfg_inmux : chcfg0_out;
    chcfg1_in = group==2'b01 ? chcfg_inmux : chcfg1_out;
    chcfg2_in = group==2'b10 ? chcfg_inmux : chcfg2_out;
end

`ifdef SIMULATION
reg  [CHCSRW-1:0] chsnap0, chsnap1,chsnap2;

always @(posedge clk) if(zero) begin
    chsnap0 <= chcfg0_out;
    chsnap1 <= chcfg1_out;
    chsnap2 <= chcfg2_out;
end
`endif

assign { sus_en, keyon_csr, block_I, fnum_I[8:0], inst_I, vol_I } = chcfg;

// Rhythm key-on CSR
localparam BD=4, SD=3, TOM=2, TC=1, HH=0;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rhy_csr <= 6'd0;
        rhy_oen <= 0;
    end else if(cen) begin
        if(slot[11]) rhy_oen <= rhy_en;
        if(slot[17]) begin
            rhy_csr <= { rhy_kon[BD], rhy_kon[HH], rhy_kon[TOM],
                         rhy_kon[BD], rhy_kon[SD], rhy_kon[TC] };
            rhy_oen <= 0;
        end else
            rhy_csr <= { rhy_csr[4:0], rhy_csr[5] };
    end
end

assign keyon_I = rhy_oen ? rhy_csr[5] : keyon_csr;

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group0(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg0_in  ),
    .drop   ( chcfg0_out )
);

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group1(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg1_in  ),
    .drop   ( chcfg1_out )
);

jtopl_sh_rst #(.width(CHCSRW),.stages(3)) u_group2(
    .clk    ( clk        ),
    .cen    ( cen        ),
    .rst    ( rst        ),
    .din    ( chcfg2_in  ),
    .drop   ( chcfg2_out )
);

endmodule
