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

module jtopl_pg_comb(
    input       [ 2:0]  block,
    input       [ 9:0]  fnum,
    // Phase Modulation
    input       [ 4:0]  lfo_mod,
    input       [ 2:0]  pms,

    output      [ 3:0]  keycode,
    // Phase increment  
    output      [16:0]  phinc_out,
    // Phase add
    input       [ 3:0]  mul,
    input       [19:0]  phase_in,
    input               pg_rst,
    // input signed [7:0]   pm_in,
    input       [16:0]  phinc_in,

    output      [19:0]  phase_out,
    output      [ 9:0]  phase_op
);

wire signed [8:0] pm_offset;

jtopl_pg_inc u_inc(
    .block      ( block     ),
    .fnum       ( fnum      ),
    .pm_offset  ( pm_offset ),
    .phinc_pure ( phinc_out )
);

// pg_sum uses the output from the previous blocks

jtopl_pg_sum u_sum(
    .mul            ( mul           ),
    .detune_signed  ( 6'd0          ),
    .phase_in       ( phase_in      ),
    .pg_rst         ( pg_rst        ),
    .phinc_pure     ( phinc_in      ),
    .phase_out      ( phase_out     ),
    .phase_op       ( phase_op      )
);

endmodule // jtopl_pg_comb