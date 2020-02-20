# Nokia 5110 screen on iCE40 Ultraplus

Sparkfun offers nokia 5110 screens: https://www.sparkfun.com/products/10168   
They have a low resolution (84x48, monochrome) but it means it can be easily implemented on an ice40 ultraplus.

The framebuffer to be displayed on screen (4032 bits) is stored in BRAM and is transferred to the screen with an interface similar to SPI.

The project is composed of the screen controller (`screen_controller.v`) which will initialise and draw on the screen. The module also contains the framebuffer which will be drawn on the screen (84x48 monochrome). Pixels can be written to the module via the simple interface (write column by column to the module).

![example](nokia_example.jpeg)
