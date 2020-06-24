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
    Date: 24-6-2020

    */

module jtopl_noise(
    input  rst,        // rst should be at least 6 clk&cen cycles long
    input  clk,        // CPU clock
    input  cen,        // optional clock enable, it not needed leave as 1'b1
    output noise
);

reg [22:0] no;
reg        nbit;

always @(*) begin
    nbit = no[0] ^ no[14];
    nbit = nbit | (no==23'd0);
end

always @(posedge clk, posedge rst) begin
    if( rst )
        no <= 23'd1<<22;
    else if(cen) begin
        no <= { nbit, no[22:1] };
    end
end

endmodule