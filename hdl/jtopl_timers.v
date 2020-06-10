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

module jtopl_timers(
  input			clk,
  input			rst,
  input         cen16,
  input			zero,
  input [7:0]	value_A,
  input [7:0]	value_B,
  input 		load_A,
  input 		load_B,
  input 		clr_flag_A,
  input 		clr_flag_B,
  output 	 	flag_A,
  output 	 	flag_B,
  output		overflow_A,
  output 	 	irq_n
);

assign irq_n = ~( flag_A | flag_B );

jtopl_timer timer_A(
	.clk		( clk		), 
	.rst		( rst		),
    .cen16      ( cen16     ),
	.zero		( zero 	    ),
	.start_value( value_A	),
	.load		( load_A   	),
	.clr_flag   ( clr_flag_A),
	.flag		( flag_A	),
	.overflow	( overflow_A)
);

jtopl_timer #(.MW(2)) timer_B(
	.clk		( clk		), 
	.rst		( rst		),
	.cen16		( cen16 	),
    .zero       ( zero      ),
	.start_value( value_B	),
	.load		( load_B   	),
	.clr_flag   ( clr_flag_B),
	.flag		( flag_B	),
	.overflow	(			)
);

endmodule

module jtopl_timer #(parameter MW=0) (
	input	   clk, 
	input	   rst,
    input      cen16,
    input	   zero,
	input	   [7:0] start_value,
	input	   load,
	input	   clr_flag,
	output reg flag,
	output reg overflow
);

localparam CW=8+MW;

reg [CW-1:0] cnt, next, init;

always@(posedge clk)
	if( clr_flag || rst)
		flag <= 1'b0;
	else if(overflow) flag<=1'b1;

always @(*) begin
    {overflow, next } = {1'b0, cnt}+1'b1;
	init = { start_value, {MW{1'b0}} };
end

always @(posedge clk)
	if( ~load || rst) begin
	  cnt  <= { start_value, {MW{1'b0}} };
	end
	else if( cen16 && zero )
	  cnt <= overflow ? init : next;

endmodule
