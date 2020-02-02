# UART

Simple implementation of UART on the iCE40 Ultraplus.

The fpga will send a byte a few time per second. Aditionaly, to demonstrate interactivity an echo is implemented where every bytes received by the fpga will be sent back.

## How to build and run

Generate the bitstream for the fpga using `make`, program the fpga with `make prog`.

Using a way to read serial on a computer (such as a ftdi usb stick or even an arduino), use a tool such as minicom: `minicom -b <baudrate> -D <device>`
