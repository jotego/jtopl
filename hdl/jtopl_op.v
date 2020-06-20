/* This file is part of JTOPL.

 
    JTOPL program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTOPL program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTOPL.  If not, see <http://www.gnu.org/licenses/>.

    Based on Sauraen VHDL version of OPN/OPN2, which is based on die shots.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 19-6-2020

*/


module jtopl_op(
    input           rst,
    input           clk,
    input           cenop,

    // these signals need be delayed
    input   [1:0]   group,
    input           op, // 0 for modulator operators
    input           con_I,
    input   [2:0]   fb_I,       // voice feedback

    input           zero,

    input   [9:0]   pg_phase_I,
    input   [9:0]   eg_atten_II, // output from envelope generator
    
    
    output reg signed [13:0] op_result
);

reg  [11:0] atten_internal_II;
reg         signbit_II, signbit_III;
reg  [13:0] prev,  prev0_din, prev1_din, prev2_din;
wire [13:0] prev0, prev1,     prev2;

wire [ 6:0] ctrl_in, ctrl_dly;
wire [ 1:0] group_d;
wire        op_d, con_I_d;
wire [ 2:0] fb_I_d;

assign      ctrl_in = { group, op, con_I, fb_I };
assign      { group_d, op_d, con_I_d, fb_I_d } = ctrl_dly;

jtopl_sh #( .width(7), .stages(3)) u_delay(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( ctrl_in   ),
    .drop   ( ctrl_dly  )
);

always @(*) begin
    prev0_din     = op_d && group_d==2'd0 ? op_result : prev0;
    prev1_din     = op_d && group_d==2'd1 ? op_result : prev1;
    prev2_din     = op_d && group_d==2'd2 ? op_result : prev2;
    case( group_d )
        default: prev = prev0;
        2'd1:    prev = prev1;
        2'd2:    prev = prev2;
    endcase
end

jtopl_sh #( .width(14), .stages(3)) u_csr0(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev0_din ),
    .drop   ( prev0     )
);

jtopl_sh #( .width(14), .stages(3)) u_csr1(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev1_din ),
    .drop   ( prev1     )
);

jtopl_sh #( .width(14), .stages(3)) u_csr2(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .din    ( prev2_din ),
    .drop   ( prev2     )
);


reg [10:0]  subtresult;

reg [12:0]  shifter, shifter_2, shifter_3;

// REGISTER/CYCLE 1
// Creation of phase modulation (FM) feedback signal, before shifting
reg signed [13:0]  x;
reg signed [14:0]  pm_preshift_I;
reg         s1_II;

always @(*) begin
    x = op_d ? op_result : prev;
    pm_preshift_I = { x[13], x }; // sign-extend
end

reg  [9:0]  phasemod_I;

always @(*) begin
    // Shift FM feedback signal
    if (op_d)
        // Bit 0 of pm_preshift_I is never used
        phasemod_I = con_I_d ? pm_preshift_I[10:1] : 10'd0;
    else
        case( fb_I_d )
            3'd0: phasemod_I = 10'd0;      
            3'd1: phasemod_I = { {4{pm_preshift_I[14]}}, pm_preshift_I[14:9] };
            3'd2: phasemod_I = { {3{pm_preshift_I[14]}}, pm_preshift_I[14:8] };
            3'd3: phasemod_I = { {2{pm_preshift_I[14]}}, pm_preshift_I[14:7] };
            3'd4: phasemod_I = {    pm_preshift_I[14],   pm_preshift_I[14:6] };
            3'd5: phasemod_I = pm_preshift_I[14:5];
            3'd6: phasemod_I = pm_preshift_I[13:4];
            3'd7: phasemod_I = pm_preshift_I[12:3];
        endcase
end

reg [ 9:0]  phase;
reg [ 7:0]  aux_I;

always @(*) begin
    phase   = phasemod_I + pg_phase_I;
    aux_I   = phase[7:0] ^ {8{~phase[8]}};
end

// REGISTER/CYCLE 1

always @(posedge clk) if( cenop ) begin    
    signbit_II <= phase[9];     
end

wire [11:0]  logsin_II;

jtopl_logsin u_logsin (
    .clk    ( clk           ),
    .cen    ( cenop         ),
    .addr   ( aux_I[7:0]    ),
    .logsin ( logsin_II     )
);

// REGISTER/CYCLE 2
// Sine table    
// Main sine table body

always @(*) begin
    subtresult = eg_atten_II + logsin_II[11:2];
    atten_internal_II = { subtresult[9:0], logsin_II[1:0] } | {12{subtresult[10]}};
end

wire [9:0] mantissa_III;
reg  [3:0] exponent_III;

jtopl_exprom u_exprom(
    .clk    ( clk       ),
    .cen    ( cenop     ),
    .addr   ( atten_internal_II[7:0] ),
    .exp    ( mantissa_III           )
);

always @(posedge clk) if( cenop ) begin
    exponent_III <= atten_internal_II[11:8];    
    signbit_III  <= signbit_II;    
end

// REGISTER/CYCLE 3
// 2's complement & Carry-out discarded

always @(*) begin    
    // Floating-point to integer, and incorporating sign bit
    // Two-stage shifting of mantissa_IIII by exponent_IIII
    shifter = { 3'b001, mantissa_III };
    case( ~exponent_III[1:0] )
        2'b00: shifter_2 = { 1'b0, shifter[12:1] }; // LSB discarded
        2'b01: shifter_2 = shifter;
        2'b10: shifter_2 = { shifter[11:0], 1'b0 };
        2'b11: shifter_2 = { shifter[10:0], 2'b0 };
    endcase
    case( ~exponent_III[3:2] )
        2'b00: shifter_3 = {12'b0, shifter_2[12]   };
        2'b01: shifter_3 = { 8'b0, shifter_2[12:8] };
        2'b10: shifter_3 = { 4'b0, shifter_2[12:4] };
        2'b11: shifter_3 = shifter_2;
    endcase
end

always @(posedge clk) if( cenop ) begin
    op_result <= ({ 1'b0, shifter_3 } ^ {14{signbit_III}}) + {13'd0,signbit_III};
end

`ifdef SIMULATION
reg signed [13:0] op_sep0_0;
reg signed [13:0] op_sep1_0;
reg signed [13:0] op_sep2_0;
reg signed [13:0] op_sep0_1;
reg signed [13:0] op_sep1_1;
reg signed [13:0] op_sep2_1;
reg signed [13:0] op_sep4_0;
reg signed [13:0] op_sep5_0;
reg signed [13:0] op_sep6_0;
reg signed [13:0] op_sep4_1;
reg signed [13:0] op_sep5_1;
reg signed [13:0] op_sep6_1;
reg signed [13:0] op_sep7_0;
reg signed [13:0] op_sep8_0;
reg signed [13:0] op_sep9_0;
reg signed [13:0] op_sep7_1;
reg signed [13:0] op_sep8_1;
reg signed [13:0] op_sep9_1;
reg        [ 4:0] sepcnt;

always @(posedge clk) if(cenop) begin
    sepcnt <= zero ? 5'd0 : sepcnt+5'd1;
    case( (sepcnt+3)%18  )
        0: op_sep0_0 <= op_result;
        1: op_sep1_0 <= op_result;
        2: op_sep2_0 <= op_result;
        3: op_sep0_1 <= op_result;
        4: op_sep1_1 <= op_result;
        5: op_sep2_1 <= op_result;
        6: op_sep4_0 <= op_result;
        7: op_sep5_0 <= op_result;
        8: op_sep6_0 <= op_result;
        9: op_sep4_1 <= op_result;
       10: op_sep5_1 <= op_result;
       11: op_sep6_1 <= op_result;
       12: op_sep7_0 <= op_result;
       13: op_sep8_0 <= op_result;
       14: op_sep9_0 <= op_result;
       15: op_sep7_1 <= op_result;
       16: op_sep8_1 <= op_result;
       17: op_sep9_1 <= op_result;
    endcase
end

`endif

endmodule
