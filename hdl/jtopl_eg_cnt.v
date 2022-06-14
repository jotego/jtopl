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

module jtopl_eg_cnt(
    input             rst,
    input             clk,
    input             cen,
    input             zero,
    output reg [15:0] eg_cnt,
    output reg [15:0] eg_carry
);

reg  [15:0] pre_sum, pre_carry;

integer aux;

always @* begin
    { pre_carry[0], pre_sum[0] } = { 1'b0, eg_cnt[0] } + 2'd1;
    for( aux=1; aux<15; aux++ ) begin
        { pre_carry[aux], pre_sum[aux] } = { 1'b0, eg_cnt[aux] } + { 1'b0, pre_carry[aux-1] };
    end
end

always @(posedge clk, posedge rst) begin : envelope_counter
    if( rst ) begin
        eg_cnt <= 0;
    end
    else begin
        if( zero && cen ) begin
            // envelope counter increases at each zero input
            // This is different from OPN/M where it increased
            // once every three zero inputs
            eg_cnt   <= pre_sum;
            eg_carry <= pre_carry;
        end
    end
end

endmodule