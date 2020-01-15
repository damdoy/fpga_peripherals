`include "ram_if.v"
`include "spi_slave.v"
`include "ov7670_controller.v"

module top(output LED_R, output LED_G, output LED_B, output IOT_51A, output IOT_39A, inout IOT_38B, input IOT_43A, output IOT_48B, input IOT_42B,
            input IOT_45A_G1, input IOT_50B, input IOB_13B, output IOT_41A,
            input IOB_16A, input IOB_18A, input IOB_20A, input IOB_31B, input IOB_29B, input IOB_25B_G3, input IOB_24A, input IOB_23B,
            input SPI_SCK, input SPI_SS, input SPI_MOSI, output SPI_MISO);
   wire clk_48mhz; //internal
   wire clk_24mhz; //clk for the camera
   wire clk_90khz;

   wire SIOC;
   wire SIOD_send;
   reg SIOD_write_en;
   reg cam_reset;
   wire SIOD_recv;
   wire VSYNC;
   wire HREF;
   wire PCLK;
   wire [7:0] CAM_PIXEL_DATA;
   wire PWRD;

   assign IOT_39A = SIOC;
   //this configuration is necessary to have tristate buffer
   assign SIOD_recv = IOT_38B;
   // assign IOT_38B = SIOD_write_en?SIOD_send:1'bZ; //in theory should be bidir signal
   assign IOT_38B = SIOD_send;
   assign IOT_48B = ~cam_reset; //reset (active low)
   assign IOT_41A = PWRD;

   assign VSYNC = IOT_50B;
   assign HREF = IOT_43A;
   assign PCLK = IOB_13B;
   assign CAM_PIXEL_DATA[7] = IOB_16A;
   assign CAM_PIXEL_DATA[6] = IOB_18A;
   assign CAM_PIXEL_DATA[5] = IOB_20A;
   assign CAM_PIXEL_DATA[4] = IOB_31B;
   assign CAM_PIXEL_DATA[3] = IOB_29B;
   assign CAM_PIXEL_DATA[2] = IOB_25B_G3;
   assign CAM_PIXEL_DATA[1] = IOB_24A;
   assign CAM_PIXEL_DATA[0] = IOB_23B;
   assign PWRD = 0;

   reg [13:0] counter_clk_48mhz; //for clock generation
   reg [2:0] led;

   // assign IOT_51A = clk_24mhz; //XLK
   assign IOT_51A = counter_clk_48mhz[1]; //12mhz

   reg start_capture;

   reg [31:0] spi_recv_data_reg;
   reg [15:0] spi_data_to_send;
   reg handle_data;
   reg spi_reset;
   wire spi_wr_buffer_free;
   reg spi_wr_en;
   reg [255:0] spi_wr_data;
   reg [255:0] spi_wr_data_buffer;
   wire spi_rd_data_available;
   reg spi_rd_data_available_buf;
   reg spi_rd_ack;
   wire [31:0] spi_rd_data;

   reg sending_image;
   reg pending_capture;
   //params for spi receive
   parameter NOP=0, INIT=1, START_READ_REQ=2, CAPTURE_IMAGE=3;

   reg [7:0] main_state;
   parameter STATE_IDLE=0, STATE_WAIT_INIT=STATE_IDLE+1, STATE_START_CAPTURE=STATE_WAIT_INIT+1, STATE_SAVING_IMG_RAM=STATE_START_CAPTURE+1;

   spi_slave spi_slave_inst(.clk(clk_24mhz), .reset(spi_reset),
      .SPI_SCK(SPI_SCK), .SPI_SS(SPI_SS), .SPI_MOSI(SPI_MOSI), .SPI_MISO(SPI_MISO),
      .wr_buffer_free(spi_wr_buffer_free), .wr_en(spi_wr_en), .wr_data(spi_wr_data),
      .rd_data_available(spi_rd_data_available), .rd_ack(spi_rd_ack), .rd_data(spi_rd_data)
   );

   //memory has 128KB, enough for a 240x240 image with 2B/pixel
   ram_if ram_if_inst(.clk(clk_24mhz), .address(ram_address), .data_in(ram_data_in), .write_en(ram_write_en), .data_out(ram_data_out));

   wire ov7670_new_image;
   wire ov7670_valid_data;
   wire [15:0] ov7670_data_out;
   reg [7:0] ov7670_reg_address;
   reg ov7670_reg_write_en;
   reg [7:0] ov7670_reg_data_in;
   wire [7:0] ov7670_reg_data_out;
   wire ov7670_capture_busy; //module currently capturing image
   ov7670_controller ov7670_controller_inst(.main_clk(clk_24mhz), .PCLK(PCLK), .CAM_DATA_IN(CAM_PIXEL_DATA), .HREF(HREF), .VSYNC(VSYNC), .CAM_RESET(cam_reset),
                          .new_img(ov7670_new_image), .valid_data(ov7670_valid_data), .data_out(ov7670_data_out),
                          .sccb_clk(clk_90khz), .SIOC(SIOC), .SIOD(SIOD_send),
                          .reg_address(ov7670_reg_address), .reg_write(ov7670_reg_write_en), .reg_data_in(ov7670_reg_data_in), .reg_data_out(ov7670_reg_data_out), .capture_busy(ov7670_capture_busy));

   reg [16:0] ram_address;
   reg [15:0] ram_data_in;
   reg ram_write_en;
   wire [15:0] ram_data_out;

   //frame capture
   reg [3:0] memory_read_req;
   reg [16:0] data_line_read;
   reg [16:0] data_column_read;
   reg [19:0] data_address_write;
   reg [16:0] data_address_spi_read;
   reg [15:0] fifo_pixels[0:7];
   parameter IMAGE_CAPTURE_SIZE = 240*240*2;

   //leds are active low
   assign LED_R = ~led[0];
   assign LED_G = ~led[1];
   assign LED_B = ~led[2];

   assign clk_24mhz = counter_clk_48mhz[0]; //divides by 2
   assign clk_90khz = counter_clk_48mhz[8];

   //internal oscillators seen as modules
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );

   initial begin
      SIOD_write_en = 0;

      led = 0;
      counter_clk_48mhz = 0;

      main_state = STATE_IDLE;

      sending_image = 0;
      pending_capture = 0;

      spi_data_to_send = 0;

      ram_address = 0;
      ram_data_in = 0;
      ram_write_en = 0;

      data_line_read = 0;
      data_column_read = 0;
      memory_read_req = 0;
      data_address_write = 0;
      //safe assumption to force a first entry in a condition
      data_address_spi_read = IMAGE_CAPTURE_SIZE+100;

      start_capture = 0;

      main_state = STATE_IDLE;
   end

   always @(posedge clk_48mhz)
   begin
      //will generate clk from this counter
      counter_clk_48mhz <= counter_clk_48mhz+1;
   end

   always @(posedge clk_24mhz)
   begin

      //defaults
      spi_rd_ack <= 0;
      spi_wr_en <= 0;
      ram_write_en <= 0;
      ov7670_reg_write_en <= 0;

      spi_rd_data_available_buf <= spi_rd_data_available;

      if(spi_rd_data_available == 1 && spi_rd_data_available_buf == 0) begin // rising edge
         spi_recv_data_reg <= spi_rd_data;
         spi_rd_ack <= 1;
         handle_data <= 1;
      end

      if(handle_data == 1) begin //received something from SPI
         case(spi_recv_data_reg[7:0])
            START_READ_REQ: begin //will send the whole image via spi
               sending_image <= 1;
            end
            CAPTURE_IMAGE: begin
               pending_capture <= 1;
            end
         endcase
         handle_data <= 0;
      end

      if(sending_image == 1 && spi_wr_buffer_free == 1 && memory_read_req == 0 && ov7670_capture_busy == 0) begin
         memory_read_req <= 4;
         if(data_address_spi_read > IMAGE_CAPTURE_SIZE) begin //two bytes per pixel
            data_address_spi_read <= 0;
         end
      end

      if(pending_capture == 1 && sending_image == 0) begin
         //start capture
         ov7670_reg_write_en <= 1;
         ov7670_reg_address <= 1;
         ov7670_reg_data_in <= 1;
         pending_capture <= 0;
      end

      case (main_state)
      STATE_IDLE: begin
         ov7670_reg_address <= 0; //read status register
         ov7670_reg_write_en <= 0; // read
         main_state <= STATE_WAIT_INIT;
      end
      STATE_WAIT_INIT: begin
         if(ov7670_reg_data_out == 0) begin // not ready
            ov7670_reg_address <= 0; //read status register
            ov7670_reg_write_en <= 0; // read
         end else begin
            main_state <= STATE_START_CAPTURE;
         end
      end
      STATE_START_CAPTURE: begin
         // start manual capture
         ov7670_reg_write_en <= 1;
         ov7670_reg_address <= 1;
         ov7670_reg_data_in <= 1;
         main_state <= STATE_SAVING_IMG_RAM;
      end
      STATE_SAVING_IMG_RAM: begin
         if( ov7670_valid_data == 1) begin //pixels incoming
            ram_address <= data_address_write;
            data_address_write <= data_address_write + 2;
            ram_write_en <= 1;
            ram_data_in <= ov7670_data_out;
         end
      end
      endcase

      //reset memory address for each new image
      if(ov7670_new_image == 1)begin
         data_address_write <= 0;
      end

      if(memory_read_req == 4) begin //nop state, to be sure that memory is free
         memory_read_req <= 3;
      end else if(memory_read_req == 3) begin
         ram_write_en <= 0;
         ram_address <= data_address_spi_read;
         memory_read_req <= 2;
      end else if (memory_read_req == 2) begin
         memory_read_req <= 1;
      end else if (memory_read_req == 1) begin
         memory_read_req <= 0;
         if(data_address_spi_read[4:0] == 5'd30) begin //only when reading byte 30 and 31, send them
            spi_wr_en <= 1;
            spi_wr_data[255:0] <= {ram_data_out[15:0], spi_wr_data_buffer[239:0]};
         end else begin
            //keep the 2 bytes in a buffer before having 32B to send
            spi_wr_data_buffer[data_address_spi_read[4:0]*8-1+16 -:16] <= ram_data_out[15:0];
         end
         data_address_spi_read <= data_address_spi_read + 2;
         if(data_address_spi_read > IMAGE_CAPTURE_SIZE-2) begin
            sending_image <= 0;
            data_address_spi_read <= 0;
         end
      end

   end

endmodule
