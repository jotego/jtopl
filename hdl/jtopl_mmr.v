/*  This file is part of JTOPL.

    JTOPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 10-6-2020
    */

module jtopl_mmr(
    input               rst,
    input               clk,
    input               cen,
    output              cenop,
    input       [ 7:0]  din,
    input               write,
    input               addr,
    output              zero,
    // Timers
    output  reg [ 7:0]  value_A,
    output  reg [ 7:0]  value_B,
    output  reg         load_A,
    output  reg         load_B,
    output  reg         flagen_A,
    output  reg         flagen_B,
    output  reg         clr_flag_A,
    output  reg         clr_flag_B,
    input               flag_A,
    input               overflow_A,
    // Phase Generator
    output      [ 9:0]  fnum_I,
    output      [ 2:0]  block_I
);

jtopl_div u_div (
    .rst            ( rst             ),
    .clk            ( clk             ),
    .cen            ( cen             ),
    .cenop          ( cenop           )
);

localparam  REG_TESTYM  =   8'h01,
            REG_CLKA    =   8'h02,
            REG_CLKB    =   8'h03,
            REG_TIMER   =   8'h04;

reg  [ 7:0] selreg;       // selected register
reg  [ 7:0] din_copy;
reg  [ 4:0] latch_fnum;
reg         csm, effect;
reg  [ 1:0] sel_group;     // group to update
reg  [ 3:0] sel_sub;       // subslot to update
reg         up_fnum, up_fbcon;

// this runs at clk speed, no clock gating here
// if I try to make this an async rst it fails to map it
// as flip flops but uses latches instead. So I keep it as sync. reset
always @(posedge clk) begin
    if( rst ) begin
        selreg    <= 8'h0;
        sel_group <= 2'd0;
        sel_sub   <= 4'd0;
        // Updaters
        up_fbcon  <= 0;
        up_fnum   <= 0;
        // timers
        { value_A, value_B } <= 16'd0;
        { clr_flag_B, clr_flag_A, load_B, load_A } <= 4'd0;
        flagen_A   <= 1;
        flagen_B   <= 1;
        din_copy   <= 8'd0;
    end else begin
        // WRITE IN REGISTERS
        if( write ) begin
            if( !addr ) begin
                selreg <= din;  
            end else begin
                // Global registers
                din_copy <= din;
                up_fnum  <= 0;
                up_fbcon <= 0;

                // General control (<0x20 registers)
                casez( selreg )
                    REG_CLKA: value_A <= din;
                    REG_CLKB: value_B <= din;
                    REG_TIMER: begin
                        clr_flag_A <= din[7];
                        clr_flag_B <= din[7];
                        flagen_A   <= ~din[6];
                        flagen_B   <= ~din[5];
                        { load_B, load_A   } <= din[1:0];
                        end
                    default:;
                endcase
                /*
                // Operator registers
                if( selreg >= 8'h20 && selreg < 8'hA0 &&
                    selreg[2:0]<=3'd5 && selreg[4:3]!=2'b11) begin
                    sel_group <= selreg[4:3];
                    sel_sub   <= selreg[2:0];
                    case( selreg[7:5] )
                        2'b001: {}
                        2'b010: 
                        2'b
                    endcase
                end                
                */
                // Channel registers
                case( selreg[7:4] )
                    4'hA: if( selreg[3:0]<=4'd8) up_fnum <= 1;
                    4'hB: latch_fnum <= din[4:0];
                    4'hC: up_fbcon <= 1;
                    default:;
                endcase
                if( selreg[7:4]>=4'hA ) begin
                    sel_group <= selreg[3:0] < 4'd3 ? 2'd0 :
                        ( selreg[3:0] < 4'd6 ? 2'd1 : 
                        ( selreg[3:0] < 4'd9 ? 2'd2 : 2'd3) );
                    sel_sub[3]   <= 0;
                    sel_sub[2:0] <= selreg[3:0] < 4'd6 ? selreg[2:0] :
                        { 1'b0, ~&selreg[2:1], selreg[0] };
                end
            end
        end
        else if(cenop) begin /* clear once-only bits */
            { clr_flag_B, clr_flag_A } <= 2'd0;
        end
    end
end

jtopl_reg u_reg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cenop         ),
    .din        ( din_copy      ),
    // Pipeline order
    .zero       ( zero          ),
    
    .sel_group  ( sel_group     ),     // group to update
    .sel_sub    ( sel_sub       ),     // subslot to update
    
    //input           csm,
    //input           flag_A,
    //input           overflow_A,

    .up_fbcon   ( up_fbcon      ),
    .up_fnum    ( up_fnum       ),
    //input           up_pms,
    //input           up_tl,
    //input           up_ks_ar,
    //input           up_sr,        
    //input           up_sl_rr,
       
    // PG
    .latch_fnum ( latch_fnum    ),
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       )
);

endmodule
