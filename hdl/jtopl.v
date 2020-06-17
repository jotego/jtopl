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
    output  signed  [15:0] sound,
    output                 sample
);

wire            cenop;

wire            write = !cs_n && !wr_n;

// Timers
wire            flag_A, flag_B, flagen_A, flagen_B;
wire    [ 7:0]  value_A;
wire    [ 7:0]  value_B;
wire            load_A, load_B;
wire            clr_flag_A, clr_flag_B;
wire            overflow_A;
wire            zero; // Single-clock pulse at the begginig of s1_enters

// Phase
wire    [ 9:0]  fnum_I;
wire    [ 2:0]  block_I;
wire    [ 3:0]  mul_II;
wire    [ 9:0]  phase_VIII;
wire            pg_rst_II;

assign          dout = { ~irq_n, flag_A, flag_B, 5'd6 };
assign          sound= 16'd0;

jtopl_mmr u_mmr(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen           ),  // external clock enable
    .cenop      ( cenop         ),  // internal clock enable
    .din        ( din           ),
    .write      ( write         ),
    .addr       ( addr          ),
    .zero       ( zero          ),
    // Timers
    .value_A    ( value_A       ),
    .value_B    ( value_B       ),
    .load_A     ( load_A        ),
    .load_B     ( load_B        ),
    .flagen_A   ( flagen_A      ),
    .flagen_B   ( flagen_B      ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .overflow_A ( overflow_A    ),
    // Phase Generator
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       )
);

jtopl_timers u_timers(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    .zero       ( zero          ),
    .value_A    ( value_A       ),
    .value_B    ( value_B       ),
    .load_A     ( load_A        ),
    .load_B     ( load_B        ),
    .flagen_A   ( flagen_A      ),
    .flagen_B   ( flagen_B      ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .flag_B     ( flag_B        ),
    .overflow_A ( overflow_A    ),
    .irq_n      ( irq_n         )
);

jtopl_pg u_pg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cenop      ( cenop         ),
    // Channel frequency
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       ),
    // Operator multiplying
    .mul_II     ( mul_II        ),
    // phase modulation from LFO (vibrato at 6.4Hz)
    .lfo_mod    ( 7'd0          ),
    .pms_I      ( 3'd0          ),
    // phase operation
    .pg_rst_II  ( pg_rst_II     ),
    
    .keycode_II (               ),
    .phase_VIII ( phase_VIII    )
);

endmodule
