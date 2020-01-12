#include <stdio.h>
#include "spi_lib.h"

#define SPI_NOP 0x00
#define SPI_INIT 0x01
#define START_READ_REQ 0x02
#define CAPTURE_IMAGE 0x03

uint8_t no_param[3] = {0x0, 0x0, 0x0};
uint8_t spi_status = 0;
uint8_t data_read[31];
uint8_t val_inv[3] = {0x38, 0xAE, 0x3B};
uint8_t val_led_yellow[3] = {0x0, 0x0, 0x3};
uint8_t val_led_blue[3] = {0x0, 0x0, 0x4};

FILE *fp;

int save_bmp(){
   spi_send(CAPTURE_IMAGE, no_param, &spi_status);
   // return;
   // usleep(250000);
   spi_send(START_READ_REQ, no_param, &spi_status); // send values bit inversion
   printf("sent: status: 0x%x\n", spi_status);
   uint counter = 0;
   // for(uint i = 0; i < 320*240/2; i++){

   uint8_t bmp_header[] = {0x42, 0x4D,
                         0x36, 0xA3, 0x02, 0x00, //size of the file (to be filled later) (240*240*3(img)+54(header))
                         0x00, 0x00,
                         0x00, 0x00,
                         0x36, 0x00, 0x00, 0x00,
                         0x28, 0x00, 0x00, 0x00,
                         0xF0, 0x00, 0x00, 0x00, //width
                         0xF0, 0x00, 0x00, 0x00, //height
                         0x01, 0x00,
                         0x18, 0x00,
                         0x00, 0x00, 0x00, 0x00,
                         0x10, 0x00, 0x00, 0x00,
                         0x13, 0x0B, 0x00, 0x00,
                         0x13, 0x0B, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00,
                         0x00, 0x00, 0x00, 0x00};


   for (size_t i = 0; i < sizeof(bmp_header); i++) {
      fprintf(fp, "%c", bmp_header[i]);
   }

   //2 bytes per pixel
   while(counter < 240*240*2){

      // printf("send SPI_READ_REQ data, status: 0x%x\n", spi_status);

      // spi_send(SPI_READ_DATA, no_param, NULL); //send read request
      spi_read(data_read, &spi_status); // read data inversion
      // printf("status: %x\n", spi_status);

      if( (spi_status&0x80) != 0){
         if(counter%(240) == 0){
            printf("\n");
            // fprintf(fp, "\n");
         }

         // printf("success receive data (status: 0x%x)\n", spi_status);

         for (size_t i = 0; i < 16; i++) {
            uint8_t pixel[2];
            pixel[0] = data_read[i*2];
            pixel[1] = data_read[i*2+1];
            printf("%x ", pixel[0]&0xF8);
            fprintf(fp, "%c", (pixel[1]&0x1F)<<3); //B (only 5bits, need to make them MSB)
            fprintf(fp, "%c", ((pixel[0]&0x07)<<5)+((pixel[1]&0xE0)>>5)); //G
            fprintf(fp, "%c", pixel[0]&0xF8); //R
         }
         counter += 32;

         // printf("%x ", data_read[0]&0xF8);
         // //bmp has inverted RGB for some reason
         // fprintf(fp, "%c", (data_read[1]&0x1F)<<3); //B (only 5bits, need to make them MSB)
         // fprintf(fp, "%c", ((data_read[0]&0x07)<<5)+((data_read[1]&0xE0)>>5)); //G
         // fprintf(fp, "%c", data_read[0]&0xF8); //R
         // counter++;
      }
      // printf("status: 0x%x\n", spi_status);
   }
}

int main()
{

   fp = fopen("output.dat", "w+");
   spi_init();

   spi_send(SPI_INIT, no_param, NULL); // init

   save_bmp();

   // spi_send(SPI_READ_REQ, no_param, &spi_status); // send values bit inversion
   // printf("send SPI_READ_REQ data, status: 0x%x\n", spi_status);
   //
   // spi_send(SPI_READ_DATA, no_param, NULL); //send read request
   // spi_read(data_read, &spi_status); // read data inversion
   //
   // for (size_t i = 0; i < 3; i++) {
   //    printf("data read read idx %i: 0x%x\n", i, data_read[i]);
   // }
   // printf("status: 0x%x\n", spi_status);

   fclose(fp);
   return 0;
}
