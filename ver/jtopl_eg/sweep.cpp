/*

	This file runs a simulation on the purely combinational logic of the envelope generator.
	The simulation is controlled via text files

	The text file is a sequence of write commands that will configure the inputs to the logic
	then a wait command will kick the simulation for a given number of clocks

	The LFO is always running. The simulations show that SSG is well implemented and that
	the circuit behaves within bounds for extreme cases

	The core logic of the ASDR envelope is simulated on separate test bench eg2.

	Arguments:
		-w write VCD	(always enabled, uncomment to evaluate this argument)
		-o path-to-test-file

*/

#include <cstring>
#include <iostream>
#include <fstream>
#include "Vsweep.h"
#include "verilated_vcd_c.h"

using namespace std;


vluint64_t main_time = 0;	   // Current simulation time
const vluint64_t HALFPERIOD=133; // 3.57MHz
Vsweep top;
VerilatedVcdC* vcd;

void clock(int n) {
	while( n-->0 ) {
		top.eval();
		vcd->dump(main_time);

		main_time += HALFPERIOD;
		top.clk=1;
		top.eval();
		vcd->dump(main_time);

		main_time += HALFPERIOD;
		top.clk=0;
	}
}

double sc_time_stamp () {	   // Called by $time in Verilog
   return main_time;
}

int main(int argc, char *argv[]) {	
	int err_code=0;
	vcd = new VerilatedVcdC;
	bool trace=true;

	if( trace ) {
		Verilated::traceEverOn(true);
		top.trace(vcd,99);
		vcd->open("test.vcd");
	}
	for( top.arate_I=0; top.arate_I<16; top.arate_I++ )
	{
		top.rst = 1;
		top.keyon_I = 0;
		clock(18*2);
		top.rst = 0;
		top.keyon_I = 1;
		clock( 80'000 );
	}


	quit:
	if(trace) vcd->close();
	// VerilatedCov::write("logs/coverage.dat");
	delete vcd;
	return err_code;
}


void remove_blanks( char*& str ) {
	while( *str!=0 && (*str==' ' || *str=='\t') ) str++;
}