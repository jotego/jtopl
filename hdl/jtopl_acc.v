/* This file is part of JTOPL.

 
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
    Date: 20-6-2020 

*/

module jtopl_acc(
    input                rst,
    input                clk,
    input                cenop,
    input         [17:0] slot,
    input                rhy_en,
    input  signed [12:0] op_result,
    input                zero,
    input                op,  // 0 for modulator operators
    input                con, // 0 for modulated connection
    output signed [15:0] snd
);

wire               sum_en;
wire signed [13:0] op2x;
wire               rhy2x;

// all rhythm channels are amplified by two
// given the data path latency, slot 16(-1) data enters at slot 6(-1) and so on
// slots 13~18 (counting from 1 to 18) will enter when bits slot[7:2] are set
assign rhy2x  = rhy_en && |slot[5:0]; // rhythm ops at slots 0-5; [7:2] missed HH@slot1
assign sum_en = op | con;
assign op2x   = rhy2x ? {op_result, 1'b0} : {op_result[12],op_result};

// ===== Per-channel volume (GLOBAL test build; same for all games) =====
// /256 fixed-point gain: 256=0dB 228=-1 203=-2 181=-3 161=-4 144=-5 128=-6dB
// Carriers land at accumulator slots via op N -> slot (N+6) mod 18:
//   ch0->slot9  ch1->slot10  ch2->slot11  ch3->slot15  (drums-> slots0-5)
localparam [8:0] VOL_CH0 = 9'd256; // ch0   0 dB
localparam [8:0] VOL_CH1 = 9'd181; // ch1  -3 dB
localparam [8:0] VOL_CH2 = 9'd203; // ch2  -2 dB
localparam [8:0] VOL_CH3 = 9'd203; // ch3  -2 dB
reg [8:0] chvol;
always @(*) case(1'b1)
    slot[ 9]: chvol = VOL_CH0;
    slot[10]: chvol = VOL_CH1;
    slot[11]: chvol = VOL_CH2;
    slot[15]: chvol = VOL_CH3;
    default:  chvol = 9'd256; // 0 dB (drums + unused)
endcase
wire signed [23:0] op_vol_full = op2x * $signed({1'b0, chvol});
wire signed [13:0] op2x_vol     = op_vol_full[21:8]; // /256, unity when chvol=256

// Continuous output
jtopl_single_acc #(.INW(14),.OUTW(16))  u_acc(
    .clk        ( clk       ),
    .cenop      ( cenop     ),
    .op_result  ( op2x_vol  ),
    .sum_en     ( sum_en    ),
    .zero       ( zero      ),
    .snd        ( snd       )
);

endmodule
