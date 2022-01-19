# JTOPL FPGA Clone of Yamaha OPL hardware by Jose Tejada (@topapate)

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation


JTOPL is an FM sound source written in Verilog, fully compatible with YM3526. This project will most likely grow to include other Yamaha chips of the OPL family.

## Features

The implementation tries to be as close to original hardware as possible. Low usage of FPGA resources has also been a design goal. 

*Accuracy*

* Follows Y8950 block diagram by Yamaha
* Barrel shift registers used for configuration values
* Takes note of all known reverse engineered information, particularly die shots
* Accurate at sample level, and at internal cycle clock where reasonable
* Original architecture kept as much as possible

*Modern Design for FPGA*

* Fully synchronous
* Clock enable input for easy integration
* Avoids bulky multiplexers

Directories:

* hdl -> all relevant RTL files, written in verilog
* ver -> test benches
* ver/verilator -> test bench that can play vgm files

## Usage

Although many files are shared, each chip has its own top level file to instantiate. There are QIP files for each one that detail the list of files used for each file. Intel Quartus software can take qip files as part of the project.

Not all the chips of OPL series are implemented yet, so take the following table as a plan which I am working on.

Chip    | Top Level Cell | QIP file   | Type        | Patches | Implemented  | Usage
--------|----------------|------------|-------------|---------|--------------|-------
YM3526  |  jtopl.v       | jt26.qip   | OPL         |         | Yes          | Bubble Bobble
YM3812  |  jtopl2.v      | jtopl2.qip | OPL2        |         | WIP          | Robocop
Y8950   |  jt8950.v      | jt8950.qip | OPL+ADPCM   |         | No           | MSX-Audio
YM2413  |  jt2413.v      | jt2413.qip | OPL-L       | Yes     | No           |
YM2423  |     -          |      -     | OPL-LX      | Yes     | No plans     | Atari ST FM cart
YMF281  |     -          |      -     | OPL-LLP     | Yes     | No plans     | Pachinko
YMF262  |  jt262.v       | jt262.qip  | OPL3        |         | No           |

### Chip differences

Chip     |  Type        | Features
---------|--------------|----------------------------------------
YM3526   | OPL          | Basic OPL
YM2413   | OPLL         | Removes depth options for vibrato/tremolo
Y8950    | OPL+ADPCM    | Adds ADPCM
YM3812   | OPL2         | Adds waveform select. Four waveforms
YMF262   | OPL3         | No CSM. More operator modes, more channels

## Simulation

There are several simulation test benches in the **ver** folder. The most important one is in the **ver/verilator** folder. The simulation script is called with the shell script **go** in the same folder. The script will compile the file **test.cpp** together with other files and the design and will simulate the tune specificied with the -f command. It can read **vgm** tunes and generate .wav output of them.

### Tested Features

Each feature is tested with a given .jtt file in the **ver/verilator/tests** folder.

Feature        | JTT File  | Status (commit) | Remarks
---------------|-----------|-----------------|--------
 TL            | TL        |                 |
 EG rates      | rates     |                 |
 fnum          | fnum_abs  | Passed 4a2c3cc  | Checks absolute value of a note
 FB            | fb        | Passed 6e6178d  |
 connection    | mod       |                 |
 EG type       | perc      |                 |
 All slots     | slots     |                 | no modulation
 All slots     | slots_mod |                 | Modulate some channels
 KSL           | ksl1/2/3  | Passed 4a2c3cc  | See note*
 AM            | am        | Passed fc6ad19  |
 Vibratto      | vib       | Passed 44a540f  |
 CSM           |           |                 | Not implemented
 OPL2 waves    | tone_w?   | Passed          | Implemented
 Keyboard split|           | Untested b4345fa| Not implemented

 Note* values don't match the app notes but implementation follows reverse engineering of OPLL and OPL3. Measuring from first note of an octave to last note of the next seems to fit better the table in the notes.

## Rhythm Instruments

They are bass drum, snare drum, tom-tom, high-hat, cymbals and top cymbals. Channels 6,7 and 8 are used for these instruments. 

For patch-based OPL chips, there were specific values for each operator register of these instruments. However, for non-patched synthesizers, the user still had to enter register values. So it looks like the benefit from the rhythm feature was:

* Ability to enter more than one key-on command at once
* Noisy phase for three instruments
* Forced no modulation on 5 five instruments

Short name | Instrument | Slot    | Phase   | EG   | Modulation |
-----------|------------|---------|---------|------|------------|
 BD        | Bass drum  | 13 & 16 |         | Drum | Normal     |
 HH        | High hat   | 14      | Special | Drum |   No       |
 TOM       | Tom tom    | 15      |         | Drum |   No       |
 SD        | Snare drum | 17      | Special | Drum |   No       |
 TOP-CYM   | Top cymbal | 18      | Special | Drum |   No       |

## Related Projects

Other sound chips from the same author (verilog RTL)

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)

Cycle accurate FM chips from Nuked (software emulation)

Chip                |  Repository
--------------------|------------------------
OPLL                | [Nuked-OPLL](https://github.com/nukeykt/Nuked-OPLL)
OPL3                | [Nuked-OPL3](https://github.com/nukeykt/Nuked-OPL3) 
YM3438              | [Nuked-OPN2](https://github.com/nukeykt/Nuked-OPN2)