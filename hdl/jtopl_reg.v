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
    Date: 13-6-2020 

*/

module jtopl_reg(
    input            rst,
    input            clk,
    input            cen,
    input      [7:0] din,
    input            write,
    // Pipeline order
    output reg       zero,
    output reg [1:0] group,
    output reg       op,            // 0 for modulator operators
    
    input      [1:0] sel_group,     // group to update
    input      [2:0] sel_sub,       // subslot to update
    
    //input           csm,
    //input           flag_A,
    //input           overflow_A,

    input            up_fbcon,
    input            up_fnum,
    input            up_mult,
    input            up_ksl_tl,
    input            up_ar_dr,
    input            up_sl_rr,
    
    // PG
    input      [7:0] latch_fnum,
    output     [9:0] fnum_I,
    output     [2:0] block_I,
    // channel configuration
    output     [2:0] fb_I,
    
    output     [3:0] mul_II,  // frequency multiplier
    output     [1:0] ksl_IV,  // key shift level
    output           amen_IV,
    output           vib_I,    
    // EG
    output           keyon_I,
    output     [5:0] tl_IV,
    output           en_sus_I, // enable sustain
    output     [3:0] arate_I,  // attack  rate
    output     [3:0] drate_I,  // decay   rate
    output     [3:0] rrate_I,  // release rate
    output     [3:0] sl_I,     // sustain level
    output           ks_II,    // key scale
    output           con_I
);

localparam CH=9;

// Each group contains three channels
// and each subslot contains six operators
reg  [2:0] subslot;

`ifdef SIMULATION
// These signals need to operate during rst
// initial state is not relevant (or critical) in real life
// but we need a clear value during simulation
initial begin
    group   = 2'd0;
    subslot = 3'd0;
    zero    = 1'b1;
end
`endif

wire       match      = { group, subslot } == { sel_group, sel_sub};
wire [2:0] next_sub   = subslot==3'd5 ? 3'd0 : (subslot+3'd1);
wire [1:0] next_group = subslot==3'd5 ? (group==2'b10 ? 2'b00 : group+2'b1) : group;

               
// channel data
wire [2:0] fb_in   = din[3:1];
wire       con_in  = din[0];

wire       up_fnum_ch  = up_fnum  & match, 
           up_fbcon_ch = up_fbcon & match,
           update_op_I = !write && sel_group == group && sel_sub == subslot;
reg        update_op_II, update_op_III, update_op_IV;

always @(posedge clk) begin : up_counter
    if( cen ) begin
        { group, subslot }  <= { next_group, next_sub };
        zero                <= { next_group, next_sub }==5'd0;
        op                  <= next_sub >= 3'd3;
    end
end

always @(posedge clk) begin
    if(write) begin
        update_op_II   <= 0;
        update_op_III  <= 0;
        update_op_IV   <= 0;
    end else if( cen ) begin
        update_op_II   <= update_op_I;
        update_op_III  <= update_op_II;
        update_op_IV   <= update_op_III;
    end
end

localparam OPCFGW = 4*8;

wire [OPCFGW-1:0] shift_out;

jtopl_csr #(.LEN(CH*2),.W(OPCFGW)) u_csr(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen            ( cen           ),
    .din            ( din           ),
    .shift_out      ( shift_out     ),
    .up_mult        ( up_mult       ),
    .up_ksl_tl      ( up_ksl_tl     ),
    .up_ar_dr       ( up_ar_dr      ),
    .up_sl_rr       ( up_sl_rr      ), 
    .update_op_I    ( update_op_I   ),
    .update_op_II   ( update_op_II  ),
    .update_op_IV   ( update_op_IV  )
);

assign { amen_IV, vib_I, en_sus_I, ks_II, mul_II,
         ksl_IV, tl_IV,
         arate_I, drate_I, 
         sl_I, rrate_I  } = shift_out;


// Memory for CH registers
localparam KONW   =  1,
           FNUMW  = 10,
           BLOCKW =  3,
           FBW    =  3,
           CONW   =  1;
localparam CHCSRW = KONW+FNUMW+BLOCKW+FBW+CONW;

wire [CHCSRW-1:0] chcfg0_out, chcfg1_out, chcfg2_out;
reg  [CHCSRW-1:0] chcfg, chcfg0_in, chcfg1_in, chcfg2_in;

wire [CHCSRW-1:0] chcfg_inmux = {
    up_fnum_ch  ? { din[5:0], latch_fnum } : { keyon_I, block_I, fnum_I },
    up_fbcon_ch ? { fb_in, con_in } : { fb_I, con_I }
}; 

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

assign { keyon_I, block_I, fnum_I, fb_I, con_I } = chcfg;

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
