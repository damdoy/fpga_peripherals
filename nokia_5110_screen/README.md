# Nokia 5110 screen on iCE40 Ultraplus

Sparkfun offers nokia 5110 screens: https://www.sparkfun.com/products/10168   
They have a low resolution (84x48, monochrome) but it means it can be easily implemented on an ice40 ultraplus.

The framebuffer to be displayed on screen (4032 bits) is stored in BRAM and is transferred to the screen with an interface similar to SPI.

![example](nokia_example.jpeg)
