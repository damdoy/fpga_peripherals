`include "bram.v"

module screen_controller(input clk_main, input [6:0] address, input [47:0] data, input wr_en, input enable,
            output reg spi_clk, output reg spi_mosi, output reg spi_d_c);
   parameter FREQ_MAIN_HZ = 24000000;
   parameter FREQ_TARGET_UART_HZ = 1000000; //could be faster (from the doc) but fast enough for a static image
   parameter HALF_UART_PERIOD = (FREQ_MAIN_HZ/FREQ_TARGET_UART_HZ)/2;

   reg [19:0] clk_counter_tx;
   reg [47:0] current_line;

   reg [6:0] current_address; //current line, address for the bram
   reg [2:0] current_byte_pos;
   reg [2:0] current_bloc; //the screen is divided vertically in 6 blocs of 1byte (48pixels)

   reg bram_rd_en;
   reg bram_wr_en;
   reg [6:0] bram_rd_addr;
   reg [6:0] bram_wr_addr;
   reg [47:0] bram_data_in;
   wire [47:0] bram_data_out;
   wire bram_valid_out;
   bram bram_inst(.clk(clk_main), .rd_en(bram_rd_en), .wr_en(bram_wr_en), .rd_addr(bram_rd_addr), .wr_addr(bram_wr_addr),
                  .data_in(bram_data_in), .data_out(bram_data_out), .valid_out(bram_valid_out));

   reg [3:0] state;
   parameter STATE_IDLE=0, STATE_INIT_EXT=STATE_IDLE+1, STATE_INIT_CONTRAST=STATE_INIT_EXT+1, STATE_INIT_BIAS=STATE_INIT_CONTRAST+1,
             STATE_INIT_NORMAL=STATE_INIT_BIAS+1, STATE_INIT_DISPLAY=STATE_INIT_NORMAL+1, STATE_FRAME=STATE_INIT_DISPLAY+1;
   parameter [7:0] INIT_EXT_VAL = 8'b00100001; //gets in extended mode register access
   parameter [7:0] INIT_CONTRAST_VAL = 8'hAC; //contrast of 0x2C (found this value by trial and error)
   parameter [7:0] INIT_BIAS_VAL = 8'h14; //bias of 4
   parameter [7:0] INIT_NORMAL_VAL = 8'b00100010; //bit1 = vertical mode
   parameter [7:0] INIT_DISPLAY_VAL = 8'b00001100; //normal display mode

   integer i;
   initial begin
      clk_counter_tx = 0;

      current_address = 0;
      current_byte_pos = 7;
      current_bloc = 0;

      spi_clk = 1;
      spi_mosi = 0;
      spi_d_c = 1;

      state = STATE_INIT_EXT;
   end

   always @(posedge clk_main)
   begin
      bram_wr_en <= 0;
      bram_rd_en <= 0;
      if(enable == 1) begin
         clk_counter_tx <= clk_counter_tx+1;
      end

      //generates clock to send data to screen
      if(clk_counter_tx == HALF_UART_PERIOD) begin
         clk_counter_tx <= 0;
         spi_clk <= ~spi_clk;
      end

      if(wr_en == 1) begin
         bram_wr_en <= 1;
         bram_wr_addr <= address[6:0];
         bram_data_in <= data;
      end

      else begin
         bram_rd_en <= 1;
         bram_rd_addr <= current_address[6:0];
         if(bram_valid_out == 1) begin
            current_line <= bram_data_out;
         end
      end

   end

   always @(negedge spi_clk)
   begin
      spi_d_c <= 0; //set mosi as "command"

      current_byte_pos <= current_byte_pos-1;

      case (state) //send the config data, then the screen data
      STATE_INIT_EXT : begin
         spi_mosi <= INIT_EXT_VAL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INIT_CONTRAST;
            current_byte_pos <= 7;
         end
      end
      STATE_INIT_CONTRAST : begin
         spi_mosi <= INIT_CONTRAST_VAL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INIT_BIAS;
            current_byte_pos <= 7;
         end
      end
      STATE_INIT_BIAS : begin
         spi_mosi <= INIT_BIAS_VAL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INIT_NORMAL;
            current_byte_pos <= 7;
         end
      end
      STATE_INIT_NORMAL : begin
         spi_mosi <= INIT_NORMAL_VAL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INIT_DISPLAY;
            current_byte_pos <= 7;
         end
      end
      STATE_INIT_DISPLAY : begin
         spi_mosi <= INIT_DISPLAY_VAL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_FRAME;
            current_byte_pos <= 7;
         end
      end
      STATE_FRAME: begin
         if(current_byte_pos == 0) begin
            current_byte_pos <= 7;
            current_bloc <= current_bloc + 1;
            if(current_bloc == 5) begin //6 blocs of 8bits => 48bit of a line
               current_bloc <= 0;
               current_address <= current_address+1;
               if(current_address >= 83) begin //84 columns
                  current_address <= 0;
               end
            end
         end
         spi_d_c <= 1; //set mosi as "data"

         //each block is adressed MSB first, which is kind of annoying
         spi_mosi <= current_line[current_byte_pos+8*current_bloc];
      end
      endcase

   end
endmodule
