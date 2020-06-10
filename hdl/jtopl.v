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

module jtopl(
    input                  rst,        // rst should be at least 6 clk&cen cycles long
    input                  clk,        // CPU clock
    input                  cen,        // optional clock enable, it not needed leave as 1'b1
    input           [ 7:0] din,
    input                  addr,
    input                  cs_n,
    input                  wr_n,
    output          [ 7:0] dout,
    output                 irq_n,
    // combined output
    output  signed  [15:0] snd,
    output                 sample
);

wire            cen16;

wire            write = !cs_n && !wr_n;

// Timers
wire            flag_A, flag_B;
wire    [7:0]   value_A;
wire    [7:0]   value_B;
wire            load_A, load_B;
wire            clr_flag_A, clr_flag_B;
wire            overflow_A;
wire            zero; // Single-clock pulse at the begginig of s1_enters

assign          dout = { ~irq_n, flag_A, flag_B, 5'b0 };
assign          snd  = 16'd0;

jtopl_mmr u_mmr(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen           ),  // external clock enable
    .cen16      ( cen16         ),  // internal clock enable
    .din        ( din           ),
    .write      ( write         ),
    .addr       ( addr          ),
    .zero       ( zero          ),
    // Timers
    .value_A    ( value_A       ),
    .value_B    ( value_B       ),
    .load_A     ( load_A        ),
    .load_B     ( load_B        ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .overflow_A ( overflow_A    )
);

jtopl_timers u_timers(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen16      ( cen16         ),
    .zero       ( zero          ),
    .value_A    ( value_A       ),
    .value_B    ( value_B       ),
    .load_A     ( load_A        ),
    .load_B     ( load_B        ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .flag_B     ( flag_B        ),
    .overflow_A ( overflow_A    ),
    .irq_n      ( irq_n         )
);

endmodule
