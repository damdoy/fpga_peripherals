#include <stdio.h>
#include "spi_lib.h"

#define SPI_NOP 0x00
#define SPI_INIT 0x01
#define START_READ_REQ 0x02
#define CAPTURE_IMAGE 0x03

uint8_t no_param[3] = {0x0, 0x0, 0x0};
uint8_t spi_status = 0;
uint8_t data_read[31];

FILE *fp;

int read_save_image(){
   spi_send(CAPTURE_IMAGE, no_param, &spi_status);
   // usleep(250000); //not needed, fpga will wait itself to take capture
   spi_send(START_READ_REQ, no_param, &spi_status); //ask fpga to send image
   printf("sent START_READ_REQ: status: 0x%x\n", spi_status);
   uint counter = 0;

   //PPM header, P3=RGB, 240x240 image max 255 values
   fprintf(fp, "P3\n240 240\n255\n");

   //2 bytes per pixel
   while(counter < 240*240*2){
      spi_read(data_read, &spi_status); // read data inversion

      if( (spi_status&0x80) != 0){ //only if there is valid data
         if(counter%(240) == 0){ //orderly output
            printf("\n");
         }

         for (size_t i = 0; i < 16; i++) {
            uint8_t pixel[2];
            pixel[0] = data_read[i*2];
            pixel[1] = data_read[i*2+1];
            printf("%x ", pixel[0]&0xF8); //for visual/debug purposes
            fprintf(fp, "%d ", pixel[0]&0xF8); //R
            fprintf(fp, "%d ", ((pixel[0]&0x07)<<5)+((pixel[1]&0xE0)>>5)); //G
            fprintf(fp, "%d ", (pixel[1]&0x1F)<<3); //B (only 5bits, need to make them MSB)

         }
         counter += 32; //receives 32bytes per spi packet
      }
   }
}

int main()
{
   fp = fopen("output.ppm", "w+");
   spi_init();

   spi_send(SPI_INIT, no_param, NULL); // init

   read_save_image();

   fclose(fp);
   return 0;
}
