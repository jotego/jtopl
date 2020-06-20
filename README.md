# JTOPL FPGA Clone of Yamaha OPL hardware by Jose Tejada (@topapate)
===================================================================

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation


JTOPL is an FM sound source written in Verilog, fully compatible with YM3526. This project will most likely grow to include other Yamaha chips of the OPL family.

# Features

The implementation tries to be as close to original hardware as possible. Low usage of FPGA resources has also been a design goal. 

* Follows Y8950 block diagram by Yamaha
* Barrel shift registers used for configuration values
* Clock enable input for easy integration
* Avoids bulky multiplexers

Directories:

hdl -> all relevant RTL files, written in verilog
ver -> test benches
ver/verilator -> test bench that can play vgm files

Usage:

YM3526: top level file hdl/jtopl.v. Use jt26.qip to automatically get all relevant files in Quartus.

# Simulation

There are several simulation test benches in the **ver** folder. The most important one is in the **ver/verilator** folder. The simulation script is called with the shell script **go** in the same folder. The script will compile the file **test.cpp** together with other files and the design and will simulate the tune specificied with the -f command. It can read **vgm** tunes and generate .wav output of them.

# Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT49](https://github.com/jotego/jt89)
OKI 6295               | [JT49](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT49](https://github.com/jotego/jt5205)