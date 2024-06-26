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

// Accumulates an arbitrary number of inputs with saturation
// restart the sum when input "zero" is high

module jtopl_single_acc #(parameter 
        INW=13,  // input data width
        OUTW=13, // output data width
        ACCW=17
)(
    input                 clk,
    input                 cenop,
    input [INW-1:0]       op_result,
    input                 sum_en,
    input                 zero,
    output reg [OUTW-1:0] snd
);

reg signed [ACCW-1:0] next, acc, current;
reg overflow;

always @(*) begin
    current  = sum_en ? {{(ACCW-INW){op_result[INW-1]}}, op_result} : {ACCW{1'b0}};
    overflow = {ACCW-OUTW{acc[ACCW-1]}}!=acc[ACCW-2:OUTW-1];
end

always @(posedge clk) if( cenop ) begin
    acc <= zero ? current : current + acc;
    if(zero)
        snd <= overflow ? {acc[ACCW-1],{OUTW-1{~acc[ACCW-1]}}} : acc[0+:OUTW];
end

endmodule