# fpga_peripherals
Various peripherals running on an iCE40 Ultraplus fpga. Each folder is a complete project designed to demonstrate how to initialise and make a piece of peripheral work. Read each subproject README for more info.

List:
- OV7670 camera single frame capture
- Nokia 5110 screen
- UART RX/TX module

## How to build

Each project uses the icestorm toolchain to generate the bitstream for the fpga, using a simple makefile to generate the bitstream and program the fpga.

**versions used:**   
Yosys 0.9  
arachne-pnr 0.1+325+0  
nextpnr-ice40 (git sha1 c365dd1)
gcc version 5.4.0  
Built on Linux Mint 18.2
