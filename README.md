# JTOPL FPGA Clone of Yamaha OPL hardware by Jose Tejada (@topapate)

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation


JTOPL is an FM sound source written in Verilog, fully compatible with YM3526. This project will most likely grow to include other Yamaha chips of the OPL family.

## Features

The implementation tries to be as close to original hardware as possible. Low usage of FPGA resources has also been a design goal. 

* Follows Y8950 block diagram by Yamaha
* Barrel shift registers used for configuration values
* Clock enable input for easy integration
* Avoids bulky multiplexers

Directories:

* hdl -> all relevant RTL files, written in verilog
* ver -> test benches
* ver/verilator -> test bench that can play vgm files

Usage:

Chip    | Top Level Cell | QIP file
--------|----------------|----------
YM3526  | hdl/jtopl.v    | jt26.qip

## Simulation

There are several simulation test benches in the **ver** folder. The most important one is in the **ver/verilator** folder. The simulation script is called with the shell script **go** in the same folder. The script will compile the file **test.cpp** together with other files and the design and will simulate the tune specificied with the -f command. It can read **vgm** tunes and generate .wav output of them.

### Tested Features

Each feature is tested with a given .jtt file in the **ver/verilator/tests** folder.

Feature       | JTT       | Remarks
--------------|-----------|--------
 TL           | TL        |
 EG rates     | rates     |
 fnum         | fnum      |
 FB           | fb        |
 connection   | mod       |
 EG type      | perc      |
 All slots    | slots     | no modulation
 All slots    | slots_mod | Modulate some channels
 keycode      | keycode   | Sweeps fnum and block, KSL also used
 AM           | am        |
 Vibratto     | vib       |
 CSM          |           | Not implemented

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)