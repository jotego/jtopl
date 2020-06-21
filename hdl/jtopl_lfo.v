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
    Date: 21-6-2020
    */

module jtopl_lfo(
    input               rst,
    input               clk,
    input               cenop,
    input               zero,
    output  reg [6:0]   lfo_mod     // 7-bit width according to spritesmind.net
);

parameter [6:0] LIM=7'd60;

reg [6:0] cnt;

always @(posedge clk) begin
    if( rst ) begin
        lfo_mod <= 7'd0;
        cnt     <= 7'd0;
    end else if( cenop && zero) begin
        if( cnt == LIM ) begin
            cnt     <= 7'd0;
            lfo_mod <= lfo_mod + 1'b1;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
end

endmodule
