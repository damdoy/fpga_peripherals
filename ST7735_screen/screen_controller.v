`include "screen_controller_memory.v"
`include "ST7735_interface.v"

module screen_controller(input clk_main, input [3:0] reg_address, input [7:0] reg_data, input reg_wr_en,
            input [6:0] pixel_addr_x, input [6:0] pixel_addr_y, input pixel_wr_en, input [15:0] pixel_wr_data,
            output spi_clk, output wire spi_mosi, input wire spi_miso, output wire spi_d_c, output wire spi_ss,
            output reg reg_valid, input wire enable);

   parameter SCREEN_SIZE = 128;

   reg [1:0] waiting_memory_data;

   ////////////// screen interface
   reg [15:0] interface_pixel_write;
   reg interface_wr_en;
   wire interface_buffer_free;
   wire interface_is_init;

   ST7735_interface #(.SCREEN_SIZE(128)) ST7735_interface_inst(.clk_main(clk_main), .pixel_write(interface_pixel_write), .wr_en(interface_wr_en), .buffer_free(interface_buffer_free), .is_init(interface_is_init),
               .spi_clk(spi_clk), .spi_mosi(spi_mosi), .spi_d_c(spi_d_c), .spi_ss(spi_ss), .enable(enable));

   /////////////// memory for the framebuffer
   reg bram_rd_en;
   reg bram_wr_en;
   reg [6:0] bram_rd_addr_x;
   reg [6:0] bram_rd_addr_y;
   reg [6:0] bram_wr_addr_x;
   reg [6:0] bram_wr_addr_y;

   reg [15:0] bram_data_in;
   wire [15:0] bram_data_out;
   wire bram_valid_out;
   screen_controller_memory screen_controller_memory_inst(.clk(clk_main), .rd_en(bram_rd_en), .wr_en(bram_wr_en), .rd_addr_x(bram_rd_addr_x), .rd_addr_y(bram_rd_addr_y),
                  .wr_addr_x(bram_wr_addr_x), .wr_addr_y(bram_wr_addr_y),
                  .data_in(bram_data_in), .data_out(bram_data_out), .valid_out(bram_valid_out));


   initial begin
      read_reg = 0;
      reg_valid = 0;

      waiting_memory_data = 0;

      bram_rd_addr_x = 0;
      bram_rd_addr_y = 0;
      bram_wr_addr_x = 0;
      bram_wr_addr_y = 0;
   end

   always @(posedge clk_main)
   begin
      bram_rd_en <= 0;
      bram_wr_en <= 0;
      interface_wr_en <= 0;

      if(enable == 1 && interface_is_init == 1) begin

         //writing pixel to the framebuffer
         if(pixel_wr_en == 1) begin
            bram_wr_addr_x <= pixel_addr_x;
            bram_wr_addr_y <= pixel_addr_y;
            bram_wr_en <= 1;
            bram_data_in <= pixel_wr_data;
         end

         if(interface_buffer_free == 1 && pixel_wr_en == 0) begin

            if(waiting_memory_data == 0) begin
               waiting_memory_data <= 1;
               bram_rd_en <= 1;
            end else if (bram_valid_out == 1) begin
               reg_valid <= 1;
               waiting_memory_data <= 0;
               interface_pixel_write <= bram_data_out;
               interface_wr_en <= 1;

               //incrementing the addresses to read from the framebuffer
               bram_rd_addr_x <= bram_rd_addr_x+1;
               if(bram_rd_addr_x == (SCREEN_SIZE-1)) begin
                  bram_rd_addr_x <= 0;
                  bram_rd_addr_y <= bram_rd_addr_y+1;
                  if(bram_rd_addr_y == (SCREEN_SIZE-1)) begin
                     bram_rd_addr_y <= 0;
                  end
               end

            end else begin
               bram_rd_en <= 1; //need to keep this at 1 until valid out
            end

         end
      end
   end
endmodule
