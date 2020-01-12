# OV7670 on Ice40 Ultraplus

Capture single 240x240 images and send them with SPI to the computer.

Pixels are RGB565, due to the 128KB memory on the ice40-UP, only 240x240 images are available.

The `spi_host/`software will read the data from SPI and save the image in a bmp file.
