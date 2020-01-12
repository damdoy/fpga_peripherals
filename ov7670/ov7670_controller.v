// `include "ram_if.v"
// `include "spi_slave.v"
`include "ov7670_registers.v"

module ov7670_controller(input main_clk, input PCLK, input [7:0] CAM_DATA_IN, input HREF, input VSYNC, output reg CAM_RESET,
                       output reg new_img, output reg valid_data, output reg [15:0] data_out,
                       input sccb_clk, output reg SIOC, output reg SIOD,
                       input [7:0] reg_address, input reg_write, input reg_data_in, output reg reg_data_out, output wire capture_busy);

   reg href_buffer;
   reg vsync_buffer;
   reg [16:0] data_line_read_sync; //reset with the href signal
   reg [16:0] data_column_read_sync;
   reg [19:0] data_address_read;
   reg image_capture_active;
   reg [11:0] capture_counter;
   reg start_capture; //wait for a vsync to start capturing
   reg [7:0] pixel_buf;
   reg [15:0] fifo_pixels[0:7];

   reg [7:0] fifo_write_addr;
   reg [7:0] fifo_write_addr_buffer;
   reg [7:0] fifo_write_addr_buffer_2;
   reg [7:0] fifo_read_addr;

   //main states
   parameter RESET_STATE = 0, WAIT_SEND_PARAM=RESET_STATE+1, WAIT_BUSY = WAIT_SEND_PARAM+1, WAIT_VALID = WAIT_BUSY+1, CAMERA_READY = WAIT_VALID+1;

   reg [7:0] main_state;
   reg [23:0] main_counter;
   //interface with SSCB
   reg [7:0] write_reg_addr;
   reg [7:0] write_reg_data;
   reg sccb_write_commit;
   reg [15:0] current_parameter;

   //SCCB
   localparam [7:0] SEND_ID_WRITE_CONST = 8'h42;
   localparam [7:0] SEND_ID_READ_CONST = 8'h43;
   reg [7:0] send_state;
   reg sccb_busy;
   reg [7:0] send_counter;

   //SSCB states
   parameter IDLE=0, SIOD_ASSERT=IDLE+1, SEND_ID_LOW_WRITE=SIOD_ASSERT+1, SEND_ID_HIGH_WRITE=SEND_ID_LOW_WRITE+1, SEND_REG_ADDR_LOW=SEND_ID_HIGH_WRITE+1,
             SEND_REG_ADDR_HIGH=SEND_REG_ADDR_LOW+1, END_SEND_WRITE_REQ=SEND_REG_ADDR_HIGH+1, SEND_ID_LOW_READ=END_SEND_WRITE_REQ+1, SEND_ID_HIGH_READ=SEND_ID_LOW_READ+1, READ_REG_LOW=SEND_ID_HIGH_READ+1,
             READ_REG_HIGH=READ_REG_LOW+1, SEND_VAL_LOW=READ_REG_HIGH+1, SEND_VAL_HIGH=SEND_VAL_LOW+1, END_SEND_WRITE_VALUE=SEND_VAL_HIGH+1;

   //registers
   reg init_finished;

   //busy == either waiting for a capture or in the middle of a capture
   assign capture_busy = start_capture | image_capture_active;

   initial begin
      data_line_read_sync = 0;
      data_column_read_sync = 0;
      data_address_read = 0;
      image_capture_active = 0;
      capture_counter = 0;
      start_capture = 0;
      fifo_write_addr = 0;
      fifo_write_addr_buffer = 0;
      fifo_write_addr_buffer_2 = 0;
      fifo_read_addr = 0;

      main_state = RESET_STATE;
      main_counter = 0;
      write_reg_addr = 0;
      write_reg_data = 0;
      sccb_write_commit = 0;
      current_parameter = 0;

      send_state = IDLE;
      sccb_busy = 0;
      send_counter = 0;
      init_finished = 0;
   end

   always @(posedge main_clk)
   begin
      //defaults
      valid_data <= 0;

      //sync
      fifo_write_addr_buffer <= fifo_write_addr;
      fifo_write_addr_buffer_2 <= fifo_write_addr_buffer;

      if(VSYNC == 1) begin
         new_img <= 1;
      end else begin
         new_img <= 0;
      end

      //start capture is a start signal, if capture is active, deactivate the start capture signal
      if( image_capture_active == 1) begin
         start_capture <= 0;
      end

      //get data from pclk clock domain, simple dual clock fifo
      if(fifo_write_addr_buffer_2 != fifo_read_addr) begin
         data_out <= fifo_pixels[fifo_read_addr];
         valid_data <= 1;
         fifo_read_addr <= fifo_read_addr + 1;
      end

      //registers handling
      if(reg_address == 0) begin //status
         reg_data_out <= init_finished;
      end
      if(reg_address == 1 && reg_write == 1) begin //start single capture
         start_capture <= 1;
      end

      case (main_state)
      RESET_STATE : begin //reset the camera
         main_counter <= main_counter + 1;
         if(main_counter < 10000) begin
            CAM_RESET <= 1;
         end else begin
            CAM_RESET <= 0;
            main_state <= WAIT_SEND_PARAM;
            main_counter <= 0;
         end

      end
      WAIT_SEND_PARAM: begin //wait a bit before sending param to the camera to allow it to process it
         main_counter <= main_counter + 1;
         if(main_counter == 100000) begin
            write_reg_addr <= camera_params_new[2*NUMBER_CAM_PARAMS_NEW*8-1-current_parameter*2*8 -:8]; //register
            write_reg_data <= camera_params_new[2*NUMBER_CAM_PARAMS_NEW*8-1-8-current_parameter*2*8 -:8]; //data
            sccb_write_commit <= 1;
            CAM_RESET <= 0;
            main_counter <= 0;
            main_state <= WAIT_BUSY;
         end
      end
      WAIT_BUSY : begin
         if(sccb_busy == 1)begin
            main_state <= WAIT_VALID;
            sccb_write_commit <= 0;
         end
      end
      WAIT_VALID : begin
         if (sccb_busy == 0) begin //write finished
            if(current_parameter+1 < NUMBER_CAM_PARAMS_NEW) begin
               current_parameter <= current_parameter + 1; //send next parameter
               main_state <= WAIT_SEND_PARAM;
            end else begin //start a capture
               if(main_counter > 12000000) begin //allow camera to process the config before capture
                  main_state <= CAMERA_READY;
               end else begin
                  main_counter <= main_counter + 1;
               end
            end
         end
      end
      CAMERA_READY : begin //end state, camera ready to capture image
         init_finished <= 1;
      end
      endcase
   end

   //sends the registers to the camera using slow clk
   always @(posedge sccb_clk)
   begin
      case (send_state)
      IDLE : begin
         SIOC <= 1;
         SIOD <= 1;
         if(sccb_write_commit == 1) begin
            send_state <= SIOD_ASSERT;
            SIOD <= 1;
            sccb_busy <= 1;
            send_counter <= 0;
         end
      end
      SIOD_ASSERT : begin
         SIOD <= 0;
         send_state <= SEND_ID_LOW_WRITE; //send camera address
      end
      SEND_ID_LOW_WRITE : begin
         SIOC <= 0;
         if(send_counter <= 7) begin
            SIOD <= SEND_ID_WRITE_CONST[7-send_counter];
         end else begin //9th bit, dont care
            SIOD <= 0;
         end
         send_state <= SEND_ID_HIGH_WRITE;
         send_counter <= send_counter + 1;
      end
      SEND_ID_HIGH_WRITE : begin
         SIOC <= 1;
         if(send_counter == 9) begin
            send_state <= SEND_REG_ADDR_LOW; //send register address
            send_counter <= 0;
         end else begin
            send_state <= SEND_ID_LOW_WRITE;
         end
      end
      SEND_REG_ADDR_LOW: begin
         SIOC <= 0;
         send_state <= SEND_REG_ADDR_HIGH;
         if(send_counter <= 7) begin
            SIOD <= write_reg_addr[7-send_counter];
         end else begin //dont care bit
            SIOD <= 0;
         end
         send_counter <= send_counter + 1;
      end
      SEND_REG_ADDR_HIGH: begin
         SIOC <= 1;
         if(send_counter == 9) begin
            // send_state <= END_SEND_WRITE_REQ; //TO DO A READ NEXT
            send_state <= SEND_VAL_LOW; //send value
            send_counter <= 0;
         end else begin
            send_state <= SEND_REG_ADDR_LOW;
         end
      end
      SEND_VAL_LOW: begin
         SIOC <= 0;
         send_state <= SEND_VAL_HIGH;
         if(send_counter <= 7) begin
            SIOD <= write_reg_data[7-send_counter];
         end else begin //dont care
            SIOD <= 0;
         end
         send_counter <= send_counter + 1;
      end
      SEND_VAL_HIGH: begin
         SIOC <= 1;
         if(send_counter == 9) begin
            send_state <= END_SEND_WRITE_VALUE;
            send_counter <= 0;
         end else begin
            send_state <= SEND_VAL_LOW;
         end
      end
      END_SEND_WRITE_VALUE: begin //end signal
         send_counter <= send_counter + 1;
         if(send_counter <= 0) begin //need to assert siod at 0 before letting sioc at 1
            SIOC <= 0;
            SIOD <= 0;
         end else if(send_counter <= 1) begin
            SIOC <= 1;
         end else if(send_counter <= 5) begin
            SIOD <= 1;
         end else if(send_counter <= 32) begin //wait a bit before next send, for security
            send_state <= IDLE;
            send_counter <= 0;
            sccb_busy <= 0;
         end
      end
      // ////////////////END WRITE REQ, TO DO A READ NEXT (NOT WORKING)
      // END_SEND_WRITE_REQ : begin
      //    send_counter <= send_counter + 1;
      //    if(send_counter <= 0) begin //need to assert siod at 0 before letting sioc at 1
      //       SIOC <= 0;
      //       SIOD <= 0;
      //    end else if(send_counter <= 1) begin
      //       SIOC <= 1;
      //    end else if(send_counter <= 5) begin
      //       SIOD <= 1;
      //    end else if(send_counter <= 100) begin
      //       SIOD <= 0;
      //       send_state <= SEND_ID_LOW_READ;
      //       send_counter <= 0;
      //    end
      // end
      // SEND_ID_LOW_READ : begin
      //    SIOC <= 0;
      //    if(send_counter <= 7) begin
      //       SIOD <= SEND_ID_READ_CONST[7-send_counter];
      //    end else begin //8th bit, dont care
      //       SIOD <= 1;
      //    end
      //    send_state <= SEND_ID_HIGH_READ;
      //    send_counter <= send_counter + 1;
      // end
      // SEND_ID_HIGH_READ : begin
      //    SIOC <= 1;
      //    if(send_counter == 9) begin
      //       send_state <= READ_REG_LOW;
      //       SIOD <= Z;
      //       send_counter <= 0;
      //    end else begin
      //       send_state <= SEND_ID_LOW_READ;
      //    end
      // end
      // READ_REG_LOW : begin
      //    SIOC <= 0;
      //    send_state <= READ_REG_HIGH;
      //    if(send_counter >= 1 && send_counter <= 8) begin
      //       read_data_value[send_counter-1] <= SIOD_recv;
      //    end
      // end
      // READ_REG_HIGH : begin
      //    SIOC <= 1;
      //    SIOD <= Z;
      //    send_state <= READ_REG_LOW;
      //    send_counter <= send_counter + 1;
      //    if(send_counter == 100) begin //this is 9th bit get out
      //       send_state <= IDLE;
      //       SIOD <= 0;
      //       read_valid <= 1;
      //       sccb_busy <= 0;
      //    end
      // end
      default : begin
      end
      endcase
   end

   always @(posedge PCLK)
   begin
      href_buffer <= HREF;
      vsync_buffer <= VSYNC;

      if(href_buffer == 1 && HREF == 0) begin //falling edge, update line counter
         data_line_read_sync <= data_line_read_sync + 1;
      end

      if(HREF == 0) begin
         data_column_read_sync <= 0;
      end

      if(VSYNC == 1) begin //new image, reset all counters
         data_address_read <= 0;
         data_column_read_sync <= 0;
         if(start_capture == 1) begin
            image_capture_active <= 1;
         end
         data_line_read_sync <= 0;

      end else if(data_address_read < 320*240*2)begin //resolution at 2B/pixel
         if(HREF == 1 && image_capture_active == 1)begin //pixels are valid
            data_column_read_sync <= data_column_read_sync + 1;
            if(data_column_read_sync[0] == 1'b0) begin //keep every second pixel in a buffer ==> want to return 16bits full pixel value
               pixel_buf <= CAM_DATA_IN;
            end else if(data_column_read_sync[0] == 2'b1) begin
               if(data_column_read_sync >= 40*2 && data_column_read_sync < 280*2) begin //want 240 width, from 320 resolution ==> truncate borders
                  fifo_pixels[fifo_write_addr] <= {CAM_DATA_IN[7:0], pixel_buf[7:0]}; //all components
                  // fifo_pixels[fifo_write_addr] <= {data_line_read_sync[7:0], data_column_read_sync[7:0]}; //send counters
                  fifo_write_addr <= fifo_write_addr + 1;
               end
            end

            data_address_read <= data_address_read + 1;
            if(data_line_read_sync == 240-1 && data_column_read_sync == 640-1) begin //all pixels sent, reset counters
               if(image_capture_active == 1) begin
                  capture_counter <= capture_counter+1;
                  if(capture_counter >= 1) begin //last capture, deactivate the image capture
                     capture_counter <= 0; //reset counter
                     image_capture_active <= 0;
                  end
               end
            end
         end
      end
   end
endmodule
