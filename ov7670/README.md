# OV7670 on iCE40 Ultraplus

The OV7670 camera is connected to the ice40 ultraplus breakout board from lattice (https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40UltraPlusBreakoutBoard)

The OV7670 camera can be configured by the fpga. This is done in the first states of the camera module. The parameters are sent using the SCCB protocol (which is just a i2c protocol).
The frequency for this protocol should be very low (<150KHz).   
The module sents 3bytes to the camera to configure it (device adress | register address | value to write).   
Around 100 parameters are sent to the camera, the sequence is the same as in the linux driver for the ov7670 camera ([Link ov7670.c linux_kernel](https://github.com/torvalds/linux/blob/master/drivers/media/i2c/ov7670.c)).   
Among other things, the configuration sets the camera to ouput RGB565 QVGA(320x240) images. Automatic white and contrast balance are also set in the configuration.

The whole system runs on a 24MHz clock. A 12MHz clock is fed to the ov7670 camera. The SCCB protocl needs to be at a lower frequency, it is currently at ~90KHz.

The images are then captured and stored in the memory of the iCE40 ultraplus. The memory being only 128KB, we can only store 240x240 images (with RGB565, each pixel takes 2 bytes).

The images are then sent with SPI to the computer. A single image is captured each time the software sends a `CAPTURE_IMAGE` command with SPI. It can then read the image with a `START_READ_REQ`.

The software in `spi_host/` will read the data from SPI and save the image in a ppm file.

The bandwidth on the SPI line is pretty slow, each packet only contain 32B of data at a pretty low frequency. The goal, in the future, would be to display the captured image on a display without using the ram, allowing for faster transmission and larger images (use the VGA resolution).

## How to build

`make` in the `ov7670/` folder to build the fpga bitstream   
`make prog` to program the fpga   
`make` in the `spi_host/` folder to build the `host` software which will connect with the camera and retrieve the image when executed.

## Pin plan

| OV7670 pin | iCE40 Ultraplus pin on breakout board | Details |
|------|---------| ---------- |
| PWDN | IOT_41A | power down |
| RST | IOT_48B | active low |
| D[0] | IOB_23B | image data |
| D[1] | IOB_24A | |
| D[2] | IOB_25B_G3 | |
| D[3] | IOB_29B | |
| D[4] | IOB_31B | |
| D[5] | IOB_20A | |
| D[6] | IOB_18A | |
| D[7] | IOB_16A | |
| XLK | IOT_51A | clock input (camera) |
| PLK | IOB_13B | clock output (camera) |
| HREF | IOT_43A | |
| VSY | IOT_50B | Vertical sync |
| SIOD | IOT_38B | data (SCCB) |
| SIOC | IOT_39A | clock (SCCB) |

## Tools used

Yosys 0.9   
arachne-pnr 0.1+325+0   
nextpnr-ice40 (git sha1 c365dd1) gcc version 5.4.0   
Built on Linux Mint 18.2   
gcc   
make   

## Example captures

![example](../examples/ov7670_test_image.png)
