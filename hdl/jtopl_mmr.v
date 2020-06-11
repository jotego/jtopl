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
    output              cen16,
    input       [7:0]   din,
    input               write,
    input               addr,
    output              zero,
    // Timers
    output  reg [7:0]   value_A,
    output  reg [7:0]   value_B,
    output  reg         load_A,
    output  reg         load_B,
    output  reg         flagen_A,
    output  reg         flagen_B,
    output  reg         clr_flag_A,
    output  reg         clr_flag_B,
    input               flag_A,
    input               overflow_A
);

jtopl_div u_div (
    .rst            ( rst             ),
    .clk            ( clk             ),
    .cen            ( cen             ),
    .cen16          ( cen16           ),
    .zero           ( zero            )
);

localparam  REG_TESTYM  =   8'h01,
            REG_CLKA    =   8'h02,
            REG_CLKB    =   8'h03,
            REG_TIMER   =   8'h04;

reg  [ 7:0] selected_register;
reg  [ 7:0] din_copy;
reg         csm, effect;


// this runs at clk speed, no clock gating here
// if I try to make this an async rst it fails to map it
// as flip flops but uses latches instead. So I keep it as sync. reset
always @(posedge clk) begin
    if( rst ) begin
        selected_register   <= 8'h0;
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
                selected_register <= din;  
            end else begin
                // Global registers
                din_copy <= din;

                // General control (<0x20 registers)
                casez( selected_register)
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
            end
        end
        else if(cen16) begin /* clear once-only bits */
            { clr_flag_B, clr_flag_A } <= 2'd0;
        end
    end
end

endmodule
