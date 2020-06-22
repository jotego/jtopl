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
    input             rst,
    input             clk,
    input             cenop,
    input             zero,
    output      [2:0] vib_cnt
);

parameter [6:0] LIM=7'd60;

reg  [12:0] cnt;

assign vib_cnt = cnt[12:10];

always @(posedge clk) begin
    if( rst ) begin
        cnt <= 13'd0;
    end else if( cenop && zero) begin
        cnt <= cnt + 1'b1;
    end
end

endmodule
