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
    Date: 13-6-2020
    
    */

module jtopl_pg_sum (
    input       [ 3:0]  mul,        
    input       [19:0]  phase_in,
    input               pg_rst,
    input signed [5:0]  detune_signed,
    input       [16:0]  phinc_pure,

    output reg  [19:0]  phase_out,
    output reg  [ 9:0]  phase_op
);

reg [16:0] phinc_premul; 
reg [19:0] phinc_mul;

always @(*) begin
    phinc_premul = phinc_pure + {{11{detune_signed[5]}},detune_signed};
    phinc_mul    = ( mul==4'd0 ) ? {3'b0,phinc_premul} : ({2'd0,phinc_premul,1'b0} * mul);
    
    phase_out   = pg_rst ? 20'd0 : (phase_in + { phinc_mul});
    phase_op    = phase_out[19:10];
end

endmodule // jtopl_pg_sum