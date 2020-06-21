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

module jtopl_pg(
    input               rst,
    input               clk,
    input               cenop,
    // Channel frequency
    input       [ 9:0]  fnum_I,
    input       [ 2:0]  block_I,
    // Operator multiplying
    input       [ 3:0]  mul_II,
    // phase modulation from LFO (vibrato at 6.4Hz)
    input       [ 6:0]  lfo_mod,
    input               vib_dep,
    input               viben_I,
    // phase operation
    input               pg_rst_II,
    
    output  reg [ 3:0]  keycode_II,
    output      [ 9:0]  phase_IV
);

parameter CH=9;

wire [ 3:0] keycode_I;
wire [16:0] phinc_I;
reg  [16:0] phinc_II;
wire [19:0] phase_drop, phase_in;
wire [ 9:0] phase_II;

always @(posedge clk) if(cenop) begin
    keycode_II      <= keycode_I;
    phinc_II        <= phinc_I;
end

jtopl_pg_comb u_comb(
    .block      ( block_I       ),
    .fnum       ( fnum_I        ),
    // Phase Modulation
    .lfo_mod    ( lfo_mod[6:2]  ),
    .vib_dep    ( vib_dep       ),
    .viben      ( viben_I       ),

    .keycode    ( keycode_I     ),
    // Phase increment  
    .phinc_out  ( phinc_I       ),
    // Phase add
    .mul        ( mul_II        ),
    .phase_in   ( phase_drop    ),
    .pg_rst     ( pg_rst_II     ),
    .phinc_in   ( phinc_II      ),

    .phase_out  ( phase_in      ),
    .phase_op   ( phase_II      )
);

jtopl_sh_rst #( .width(20), .stages(2*CH) ) u_phsh(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .rst    ( rst       ),
    .din    ( phase_in  ),
    .drop   ( phase_drop)
);

jtopl_sh_rst #( .width(10), .stages(2) ) u_pad(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .rst    ( rst       ),  
    .din    ( phase_II  ),
    .drop   ( phase_IV  )
);

endmodule

