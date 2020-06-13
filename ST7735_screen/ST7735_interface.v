//the state machine will first send the init commands to set up the screen, then it will be
//stuck in the send pixels mode and wait the pixels from the outside to send to the screen one by one
module ST7735_interface(input clk_main, input [15:0] pixel_write, input wr_en, output reg buffer_free, output reg is_init,
            output reg spi_clk, output reg spi_mosi, output reg spi_d_c, output reg spi_ss, input wire enable);
   parameter FREQ_MAIN_HZ = 24000000;
   parameter FREQ_TARGET_SPI_HZ = 8000000;
   parameter HALF_UART_PERIOD = (FREQ_MAIN_HZ/FREQ_TARGET_SPI_HZ)/2;

   parameter SCREEN_SIZE = 128; //pixel size displayed on screen
   parameter TOTAL_SCREEN_SIZE = 131; //pixel size internally represented

   reg [24:0] clk_counter_tx;
   reg [24:0] counter_send_interval; //to wait between the commands
   reg [7:0] counter_current_param;

   reg [4:0] current_byte_pos;
   reg [19:0] current_pixel;

   reg [15:0] buffer_pixel_write;

   reg advertise_pixel_consume;
   reg advertise_pixel_consume_buffer;
   reg [15:0] pixel_display;

   reg [5:0] state;
   parameter STATE_IDLE=0, STATE_SEND_SWRESET=STATE_IDLE+1, STATE_INTERVAL_SWRESET=STATE_SEND_SWRESET+1, STATE_SEND_SLPOUT=STATE_INTERVAL_SWRESET+1,
             STATE_INTERVAL_SLPOUT=STATE_SEND_SLPOUT+1, STATE_SEND_PARAMS=STATE_INTERVAL_SLPOUT+1, STATE_SEND_INVCTR=STATE_SEND_PARAMS+1, STATE_SEND_INVCTR_PARAM=STATE_SEND_INVCTR+1,
             STATE_SEND_CMD_PWCTR1=STATE_SEND_INVCTR_PARAM+1, STATE_SEND_PWCTR1_PARAMS=STATE_SEND_CMD_PWCTR1+1,
             STATE_SEND_CMD_PWCTR4=STATE_SEND_PWCTR1_PARAMS+1, STATE_SEND_PWCTR4_PARAMS=STATE_SEND_CMD_PWCTR4+1, STATE_SEND_CMD_PWCTR5=STATE_SEND_PWCTR4_PARAMS+1, STATE_SEND_PWCTR5_PARAMS=STATE_SEND_CMD_PWCTR5+1,
             STATE_SEND_CMD_VMCTR1=STATE_SEND_PWCTR5_PARAMS+1, STATE_SEND_VMCTR1_PARAM=STATE_SEND_CMD_VMCTR1+1,
             STATE_SEND_CMD_INVOFF=STATE_SEND_VMCTR1_PARAM+1,
             STATE_SEND_CMD_MADCTL=STATE_SEND_CMD_INVOFF+1, STATE_SEND_MADCTL_PARAM=STATE_SEND_CMD_MADCTL+1,
             STATE_SEND_CMD_COLMOD=STATE_SEND_MADCTL_PARAM+1, STATE_SEND_COLMOD_PARAM=STATE_SEND_CMD_COLMOD+1,
             STATE_SEND_CMD_CASET=STATE_SEND_COLMOD_PARAM+1, STATE_SEND_CASET_PARAMS=STATE_SEND_CMD_CASET+1, STATE_SEND_CMD_RASET=STATE_SEND_CASET_PARAMS+1, STATE_SEND_RASET_PARAMS=STATE_SEND_CMD_RASET+1,
             STATE_SEND_NORON=STATE_SEND_RASET_PARAMS+1, STATE_INTERVAL_NORON=STATE_SEND_NORON+1,
             STATE_SEND_DISPON=STATE_INTERVAL_NORON+1, STATE_INTERVAL_DISPON=STATE_SEND_DISPON+1, STATE_SEND_READ_REQ=STATE_INTERVAL_DISPON+1, STATE_READ_VAL=STATE_SEND_READ_REQ+1,
             STATE_SEND_RAMWR_INIT=STATE_READ_VAL+1,
             STATE_FRAME_INIT=STATE_SEND_RAMWR_INIT+1,
             STATE_SEND_RAMWR=STATE_FRAME_INIT+1,
             STATE_FRAME=STATE_SEND_RAMWR+1, STATE_WAITING_PIXEL=STATE_FRAME+1, STATE_STOP=STATE_WAITING_PIXEL+1;

   parameter [7:0] CMD_SWRESET = 8'h01; //software reset
   parameter [7:0] CMD_SLPOUT = 8'h11; //sleep out
   parameter [7:0] CMD_INVCTR = 8'hb4; //display inversion control
   parameter [7:0] CMD_PARAM_INVCTR = 8'h07; //normal mode
   parameter [7:0] CMD_PWCTR1 = 8'hC0;
   parameter [7:0] CMD_PARAM1_PWCTR1 = 8'h82;
   parameter [7:0] CMD_PARAM2_PWCTR1 = 8'h02;
   parameter [7:0] CMD_PARAM3_PWCTR1 = 8'h84;
   parameter [7:0] CMD_PWCTR4 = 8'hC3;
   parameter [7:0] CMD_PARAM1_PWCTR4 = 8'h8A;
   parameter [7:0] CMD_PARAM2_PWCTR4 = 8'h2E;
   parameter [7:0] CMD_PWCTR5 = 8'hC4;
   parameter [7:0] CMD_PARAM1_PWCTR5 = 8'h8A;
   parameter [7:0] CMD_PARAM2_PWCTR5 = 8'hAA;
   parameter [7:0] CMD_VMCTR1 = 8'hC5;
   parameter [7:0] CMD_PARAM_VMCTR1 = 8'h0E;
   parameter [7:0] CMD_INVOFF = 8'h20;
   parameter [7:0] CMD_MADCTL = 8'h36;
   parameter [7:0] CMD_PARAM_MADCTL = 8'hC8;
   parameter [7:0] CMD_COLMOD = 8'h3A;
   parameter [7:0] CMD_PARAM_COLMOD = 8'h05;
   parameter [7:0] CMD_CASET = 8'h2A;
   //start and end of column position to draw on the screen
   //the drawable area is not starting at 0, but 2
   parameter [7:0] CMD_PARAM1_CASET = 8'h00;
   parameter [7:0] CMD_PARAM2_CASET = 8'h02;
   parameter [7:0] CMD_PARAM3_CASET = 8'h00;
   parameter [7:0] CMD_PARAM4_CASET = 8'h81;
   //start and end of row position to draw on the screen
   //the drawable area is not starting at 0, but 3
   parameter [7:0] CMD_RASET = 8'h2B;
   parameter [7:0] CMD_PARAM1_RASET = 8'h00;
   parameter [7:0] CMD_PARAM2_RASET = 8'h03;
   parameter [7:0] CMD_PARAM3_RASET = 8'h00;
   parameter [7:0] CMD_PARAM4_RASET = 8'h82;
   parameter [7:0] CMD_NORON = 8'h13;
   parameter [7:0] CMD_DISPON = 8'h29;
   parameter [7:0] CMD_RAMWR = 8'h2C;

   initial begin
      clk_counter_tx = 0;

      current_byte_pos = 7;
      current_pixel = 0;
      counter_send_interval = 0;
      counter_current_param = 0;

      spi_clk = 1;
      spi_mosi = 0;
      spi_d_c = 1;
      spi_ss = 1;

      read_reg = 0;
      reg_valid = 0;
      buffer_pixel_write = 0;

      is_init = 0;

      buffer_free = 1;
      pixel_write_free = 0;

      advertise_pixel_consume = 0;
      advertise_pixel_consume_buffer = 0;
      pixel_display = 0;

      state = STATE_SEND_SWRESET;
   end

   always @(posedge clk_main)
   begin
      if(enable == 1) begin
         clk_counter_tx <= clk_counter_tx+1;
      end

      //generate clock for the spi
      if(clk_counter_tx == HALF_UART_PERIOD) begin
         clk_counter_tx <= 0;
         spi_clk <= ~spi_clk;
      end

      //read pixel, will be consumed by the SPI state machine
      if(wr_en == 1) begin
         buffer_pixel_write <= pixel_write;
         buffer_free <= 0;
      end

      //get info that the spi has read the buffer (synchronised)
      advertise_pixel_consume_buffer <= advertise_pixel_consume;

      if(advertise_pixel_consume_buffer != advertise_pixel_consume) begin
         buffer_free <= 1;
      end

   end

   always @(negedge spi_clk)
   begin
      spi_d_c <= 0; //set mosi as "command"
      spi_ss <= 1;

      current_byte_pos <= current_byte_pos-1;

      case (state) //send the config data, then the screen data
      STATE_SEND_SWRESET : begin
         spi_mosi <= CMD_SWRESET[current_byte_pos];
         spi_ss <= 0;
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SWRESET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SWRESET : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/12)) begin //wait 150ms
            state <= STATE_SEND_SLPOUT;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_SLPOUT : begin
         spi_ss <= 0;
         spi_mosi <= CMD_SLPOUT[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SLPOUT;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SLPOUT : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/4)) begin //wait 500ms
            state <= STATE_SEND_INVCTR;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_INVCTR : begin
         spi_ss <= 0;
         spi_mosi <= CMD_INVCTR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_INVCTR_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_INVCTR_PARAM: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_INVCTR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_PWCTR1;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR1: begin
         spi_ss <= 0;
         spi_mosi <= CMD_PWCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR1_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR1_PARAMS: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR1[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR1[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_PWCTR1[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 2) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_PWCTR4;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR4: begin
         spi_ss <= 0;
         spi_mosi <= CMD_PWCTR4[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR4_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR4_PARAMS: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR4[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR4[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 1) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_PWCTR5;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR5: begin
         spi_ss <= 0;
         spi_mosi <= CMD_PWCTR5[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR5_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR5_PARAMS: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR5[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR5[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 1) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_VMCTR1;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_VMCTR1: begin
         spi_ss <= 0;
         spi_mosi <= CMD_VMCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_VMCTR1_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_VMCTR1_PARAM: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_VMCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_INVOFF;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_INVOFF: begin
         spi_ss <= 0;
         spi_mosi <= CMD_INVOFF[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_MADCTL;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_CMD_MADCTL: begin
         spi_ss <= 0;
         spi_mosi <= CMD_MADCTL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_MADCTL_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_MADCTL_PARAM: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_MADCTL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_COLMOD;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_COLMOD: begin
         spi_ss <= 0;
         spi_mosi <= CMD_COLMOD[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_COLMOD_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_COLMOD_PARAM: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_COLMOD[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_CASET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_CASET: begin
         spi_ss <= 0;
         spi_mosi <= CMD_CASET[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_CASET_PARAMS: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_CASET[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_CASET[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_CASET[current_byte_pos];
         end
         if(counter_current_param == 3) begin
            spi_mosi <= CMD_PARAM4_CASET[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 3) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_RASET;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_RASET: begin
         spi_ss <= 0;
         spi_mosi <= CMD_RASET[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_RASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_RASET_PARAMS: begin
         spi_ss <= 0;
         spi_d_c <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_RASET[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_RASET[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_RASET[current_byte_pos];
         end
         if(counter_current_param == 3) begin
            spi_mosi <= CMD_PARAM4_RASET[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 3) begin
               counter_current_param <= 0;
               if(is_init) begin
                  state <= STATE_SEND_RAMWR;
               end
               else begin
                  state <= STATE_SEND_NORON;
               end
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end

      STATE_SEND_NORON : begin
         spi_ss <= 0;
         spi_mosi <= CMD_NORON[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_NORON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_NORON : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/200)) begin //wait 10ms
            state <= STATE_SEND_DISPON;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_DISPON : begin
         spi_ss <= 0;
         spi_mosi <= CMD_DISPON[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_DISPON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_DISPON : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/20)) begin //wait 100ms
            state <= STATE_SEND_RAMWR_INIT;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_RAMWR_INIT: begin
         spi_ss <= 0;
         spi_mosi <= CMD_RAMWR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_FRAME_INIT;
            current_byte_pos <= 15;
            counter_send_interval <= 0;
         end
      end

      //will fill the framebuffer in the ST7735 as completely black
      //the ST7735 has more memory (131x131) as it is displayed, but we
      //fill it with black pixels
      STATE_FRAME_INIT: begin
         spi_ss <= 0;
         if(current_byte_pos == 0) begin
            current_byte_pos <= 15;
            current_pixel <= current_pixel + 1;
            if(current_pixel == TOTAL_SCREEN_SIZE*TOTAL_SCREEN_SIZE-1) begin
               current_pixel <= 0;
               state <= STATE_SEND_CMD_CASET; //go back to the CASET param and then draw pixels
               is_init <= 1; //finish the init sequence, advertise to the upper modules
            end
         end
         spi_d_c <= 1; //set mosi as "data"
         spi_mosi <= 0; //black
      end

      STATE_SEND_RAMWR: begin
         spi_ss <= 0;
         spi_mosi <= CMD_RAMWR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_WAITING_PIXEL;
            current_byte_pos <= 15;
            counter_send_interval <= 0;
         end
      end
      STATE_WAITING_PIXEL: begin
         spi_ss <= 1;
         if(buffer_free == 0) begin
            state <= STATE_FRAME;
            //consume next pixel and advertise the register system
            pixel_display <= buffer_pixel_write;
            advertise_pixel_consume <= ~advertise_pixel_consume;
            current_byte_pos <= 15;
         end
      end
      STATE_FRAME: begin
         spi_ss <= 0;
         if(current_byte_pos == 0) begin

            current_byte_pos <= 15;
            current_pixel <= current_pixel + 1;
            if(current_pixel == SCREEN_SIZE*SCREEN_SIZE-1) begin //image finished
               current_pixel <= 0;
               state <= STATE_SEND_RAMWR; //send a new frame
               reg_valid <= 1;
            end
            else begin
               state <= STATE_WAITING_PIXEL;
            end
         end
         spi_d_c <= 1; //set mosi as "data"
         spi_mosi <= pixel_display[current_byte_pos];
      end
      STATE_STOP: begin
      end
      endcase
   end

endmodule
