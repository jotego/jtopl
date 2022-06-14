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

module jtopl_eg_step(
    input             attack,
    input      [ 4:0] base_rate,
    input      [ 3:0] keycode,
    input      [15:0] eg_cnt,
    input      [15:0] eg_carry,
    input             ksr,
    output reg        step,
    output reg [ 5:0] rate,
    output reg        sum_up
);

reg  [6:0]   pre_rate;

always @(*) begin : pre_rate_calc
    if( base_rate == 5'd0 )
        pre_rate = 7'd0;
    else
        pre_rate = { 1'b0, base_rate, 1'b0 } +  // base_rate LSB is always zero except for RR
            ({ 3'b0, keycode } >> (ksr ? 1 : 3));
end

always @(*)
    rate = pre_rate>=7'b1111_00 ? 6'b1111_11 : pre_rate[5:0];

reg [ 4:0] mux_sel;
reg [ 2:0] cnt;

always @(*) begin
    mux_sel = attack ? (rate[5:2]+4'd1): {1'b0,rate[5:2]};
end

always @* begin
    // a rate of zero keeps the level still because sum_up is zero
    case( rate[5:2] )
        0:  { cnt, sum_up } = { 3'd0, 1'd0 };
        1:  { cnt, sum_up } = { eg_cnt[11: 9], eg_carry[ 8] };
        2:  { cnt, sum_up } = { eg_cnt[10: 8], eg_carry[ 7] };
        3:  { cnt, sum_up } = { eg_cnt[ 9: 7], eg_carry[ 6] };
        4:  { cnt, sum_up } = { eg_cnt[ 8: 6], eg_carry[ 5] };
        5:  { cnt, sum_up } = { eg_cnt[ 7: 5], eg_carry[ 4] };
        6:  { cnt, sum_up } = { eg_cnt[ 6: 4], eg_carry[ 3] };
        7:  { cnt, sum_up } = { eg_cnt[ 5: 3], eg_carry[ 2] };
        8:  { cnt, sum_up } = { eg_cnt[ 4: 2], eg_carry[ 1] };
        9:  { cnt, sum_up } = { eg_cnt[ 3: 1], eg_carry[ 0] };
        10: { cnt, sum_up } = { eg_cnt[ 2: 0], 1'b1 };
        11: { cnt, sum_up } = { eg_cnt[ 2: 0], 1'b1 };
        12: { cnt, sum_up } = { eg_cnt[ 2: 0], 1'b1 };
        13: { cnt, sum_up } = { eg_cnt[ 2: 0], 1'b1 };
        14: { cnt, sum_up } = { eg_cnt[ 2: 0], 1'd1 };
        15: { cnt, sum_up } = { 3'd7, 1'd1 };
    endcase
end

////////////////////////////////
reg [7:0] step_idx;

always @(*) begin : rate_step
    if( rate[5:4]==2'b11 ) begin // 0 means 1x, 1 means 2x
        if( rate[5:2]==4'hf && attack)
            step_idx = 8'b11111111; // Maximum attack speed, rates 60&61
        else
        case( rate[1:0] )
            2'd0: step_idx = 8'b00000000;
            2'd1: step_idx = 8'b10001000; // 2
            2'd2: step_idx = 8'b10101010; // 4
            2'd3: step_idx = 8'b11101110; // 6
        endcase
    end
    else begin
        if( rate[5:2]==4'd0 && !attack)
            step_idx = 8'b11111110; // limit slowest decay rate
        else
        case( rate[1:0] )
            2'd0: step_idx = 8'b10101010; // 4
            2'd1: step_idx = 8'b11101010; // 5
            2'd2: step_idx = 8'b11101110; // 6
            2'd3: step_idx = 8'b11111110; // 7
        endcase
    end
    step = /*rate[5:1]==5'd0 ? 1'b0 :*/ step_idx[ cnt ];
end

endmodule // eg_step