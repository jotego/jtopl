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
    Date: 17-6-2020

    */

module jtopl_eg_final(
    input      [6:0] lfo_mod,
    input            amsen,
    input            ams,
    input      [5:0] tl,
    input      [1:0] ksl,   // level damped by pitch
    input      [3:0] keycode,
    input      [9:0] eg_pure_in,
    output reg [9:0] eg_limited
);

reg [ 8:0]  am_final;
reg [11:0]  sum_eg_tl;
reg [11:0]  sum_eg_tl_am;
reg [ 5:0]  am_inverted;
reg [ 5:0]  ksl_dB;

always @(*) begin
    am_inverted = lfo_mod[6] ? ~lfo_mod[5:0] : lfo_mod[5:0];
    case( ksl )
        2'd0: ksl_dB = 6'd0;
        2'd1: ksl_dB = {2'd0,keycode};
        2'd2: ksl_dB = {1'd0,keycode,1'b0};
        2'd3: ksl_dB = {keycode, 2'b0};
    endcase
end

// Although it is possible to achieve about the 1dB and 4.8dB values
// shown in the application notes; this implementation makes more sense.
// It uses two bits for modulation and produces 1.1 and 4.5dB
// I think this is the likely way real hardware works, so until I have
// evidence against it, I'll keep it this way:

always @(*) begin
    casez( {amsen, ams } )
        default: am_final = 9'd0;
        2'b1_0: am_final = { 5'd0, am_inverted[5:4], 2'b0 }; // Max 1.1 dB
        2'b1_1: am_final = { 3'd0, am_inverted[5:4], 4'b0 };   // Max 4.5 dB
        // Just for reference, how to obtain other attenuation values:
        //2'b1_0: am_final = { 5'd0, am_inverted[5:2]      }; // Max 1.4 dB
        //2'b1_0: am_final = { 5'd0, am_inverted[5:3], 1'b0  }; // Max 1.3 dB
        //2'b1_0: am_final = { 5'd0, am_inverted[5], 2'b0,am_inverted[4]  }; // Max 0.8 dB
        //2'b1_0: am_final = { 5'd0, am_inverted[5], 1'b0, am_inverted[4], 1'b0  }; // Max 0.9 dB
        //2'b1_1: am_final = { 3'd0, am_inverted[5:4],2'b0,am_inverted[3:2] }; // Max 4.8 dB
        //2'b1_1: am_final = { 3'd0, am_inverted[5:3],3'b0 }; // Max 4.5 dB
        //2'b1_1: am_final = { 3'd0, am_inverted[5:4],1'b0,am_inverted[3], 2'b0 }; // Max 4.9 dB
    endcase
    sum_eg_tl = {  2'b0, tl,     3'd0 } + 
                {  2'b0, ksl_dB, 3'd0 } +
                {  1'b0, eg_pure_in}; // leading zeros needed to compute correctly
    sum_eg_tl_am = sum_eg_tl + { 3'd0, am_final };
end

always @(*)  
    eg_limited = sum_eg_tl_am[11:10]==2'd0 ? sum_eg_tl_am[9:0] : 10'h3ff;

endmodule