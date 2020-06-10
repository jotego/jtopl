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

module jtopl_div(
    input       rst,
    input       clk,
    input       cen,
    output reg  cen16,
    output reg  zero
);

reg  [3:0] cnt;
reg  [4:0] zcnt;

`ifdef SIMULATION
initial cnt=4'd0;
`endif

always @(posedge clk) if(cen) begin
    cnt <= cnt+4'd1;
end

always @(posedge clk) begin
    cen16 <= cen && &cnt;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        zcnt <= 5'd0;
        zero <= 0;
    end else if(cen16) begin
        zcnt <= zcnt==5'd18 ? 5'd0 : zcnt+5'd1;
        zero <= zcnt==5'd18;
    end
end


endmodule
