`include "screen_controller.v"

module top(output IOT_39A, output IOT_38B, output IOT_43A, output IOT_42B, output IOT_48B,
            output LED_R, output LED_G, output LED_B, output IOT_41A);

   wire clk_48mhz;
   wire clk_24mhz;
   reg clk_div;

   assign clk_24mhz = clk_div;

   wire SCE; //chip select for the screen
   reg RST;
   wire D_C;
   wire MOSI;
   wire SCLK; //clock

   assign IOT_48B = SCLK;
   assign IOT_42B = MOSI;
   assign IOT_39A = SCE;
   assign IOT_38B = RST; //ative low
   assign IOT_43A = D_C;

   //internal oscillators seen as modules
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );

   reg [2:0] led;

   reg [23:0] counter_start; //to put screen in reset for a while
   reg [23:0] counter_redraw; //resent the image to the frame buffer a few times per second

   //position for the square drawn on screen
   reg [6:0] square_start_x;
   reg [6:0] square_start_y;
   reg square_vector_x;
   reg square_vector_y;

   reg draw_frame; //currently drawing the scene
   reg first_pixel; //keep first pixel reg in a buffer to avoid updating indices at first clk

   //LEDs
   assign LED_R = ~led[0];
   assign LED_G = ~led[1];
   assign LED_B = ~led[2];

   //screen has register map that isn't used, for extension purposes
   reg [3:0] screen_controller_reg_address;
   reg [7:0] screen_controller_reg_data;
   reg screen_controller_reg_wr_en;

   //controls to send data to the screen
   reg [6:0] screen_controller_pixel_addr_x;
   reg [6:0] screen_controller_pixel_addr_y;
   reg screen_controller_pixel_wr_en;
   reg [15:0] screen_controller_pixel_wr_data;
   wire screen_controller_reg_valid;

   //indicates that the screen has been initialised and setup
   reg screen_controller_enable;
   
   screen_controller screen_controller_inst(.clk_main(clk_24mhz), .reg_address(screen_controller_reg_address), .reg_data(screen_controller_reg_data), .reg_wr_en(screen_controller_reg_wr_en),
               .pixel_addr_x(screen_controller_pixel_addr_x), .pixel_addr_y(screen_controller_pixel_addr_y), .pixel_wr_en(screen_controller_pixel_wr_en), .pixel_wr_data(screen_controller_pixel_wr_data),
               .spi_clk(SCLK), .spi_mosi(MOSI), .spi_d_c(D_C), .spi_ss(SCE),
               .reg_valid(screen_controller_reg_valid), .enable(screen_controller_enable));

   initial begin
      clk_div = 0;

      // SCE = 1;
      RST = 0;
      LED = 0;

      led = 0;
      counter_start = 0;
      counter_redraw = 0;
      address_to_draw = 0;
      first_pixel = 1;
      square_vector_x = 0;
      square_vector_y = 0;

      square_start_x = 64;
      square_start_y = 48;

      screen_controller_address = 0;
      screen_controller_data = 0;
      screen_controller_reg_wr_en = 0;
      screen_controller_enable = 0;
      screen_controller_pixel_addr_x = 0;
      screen_controller_pixel_addr_y = 0;
      screen_controller_pixel_wr_en = 0;
      screen_controller_pixel_wr_data = 0;

      draw_frame = 1;
   end

   always @ (posedge clk_48mhz) begin
      clk_div <= ~clk_div; //clock divider
   end

   always @(posedge clk_24mhz)
   begin

      screen_controller_pixel_wr_en <= 0;

      //register control, not used
      screen_controller_address <= 0;
      screen_controller_reg_wr_en <= 0;

      if(counter_start < 24'hf00000) begin //screen in reset mode
         counter_start <= counter_start + 1;
         led[0] <= 1; //turn LED on when screen inits
         if(counter_start == 24'h800000) begin
            RST <= 1;
         end
      end else begin //starts the screen
         screen_controller_enable <= 1;

         if(screen_controller_reg_valid == 1) begin
            if(draw_frame == 1) begin

               //add red value to pixel if within the square dimensions
               if(screen_controller_pixel_addr_x >= square_start_x && screen_controller_pixel_addr_x <= square_start_x+16
                  && screen_controller_pixel_addr_y >= square_start_y && screen_controller_pixel_addr_y <= square_start_y+16) begin
                  screen_controller_pixel_wr_data[15:11] <= 5'b11111;
               end else begin
                  screen_controller_pixel_wr_data[15:11] <= 5'b00000;
               end

               //green gradient, 64 (6bits) different values on a 128 wide screen
               if(screen_controller_pixel_addr_x[0] == 1'b1) begin
                  screen_controller_pixel_wr_data[10:5] <= screen_controller_pixel_wr_data[10:5]+1;
               end

               if(first_pixel == 1) begin //dont update addresses for first write
                  first_pixel <= 0;
                  screen_controller_pixel_wr_en <= 1;
               end else begin
                  screen_controller_pixel_addr_x <= screen_controller_pixel_addr_x+1;
                  if(screen_controller_pixel_addr_x == 127) begin
                     screen_controller_pixel_addr_x <= 0;
                     screen_controller_pixel_addr_y <= screen_controller_pixel_addr_y+1;

                     //green gradient, 32 (5bits) different values on a 128 wide screen (increase every 4 pixels)
                     if(screen_controller_pixel_addr_y[1:0] == 2'b11) begin
                        screen_controller_pixel_wr_data[4:0] <= screen_controller_pixel_wr_data[4:0]+1;
                     end

                     //sent the whole image
                     if(screen_controller_pixel_addr_y == 127) begin
                        draw_frame <= 0;
                     end
                  end
                  screen_controller_pixel_wr_en <= 1;
               end
            end
            else begin
               if(counter_redraw < 24'h100000) begin
                  counter_redraw <= counter_redraw + 1;
               end else begin //start a new image, update square position
                  first_pixel <= 1;
                  draw_frame <= 1;
                  led[0] <= 0; //turn LED off when screen is init
                  counter_redraw <= 0;

                  //collision detection for the square on X axis
                  if(square_vector_x == 0) begin
                     square_start_x <= square_start_x + 2;
                     if(square_start_x+16 == 126) begin
                        square_vector_x <= 1;
                        square_start_x <= square_start_x - 2;
                     end
                  end else begin
                     square_start_x <= square_start_x - 2;
                     if(square_start_x == 0) begin
                        square_vector_x <= 0;
                        square_start_x <= square_start_x + 2;
                     end
                  end

                  //collision detection for the square on Y axis
                  if(square_vector_y == 0) begin
                     square_start_y <= square_start_y + 1;
                     if(square_start_y+16 == 127) begin
                        square_vector_y <= 1;
                        square_start_y <= square_start_y - 1;
                     end
                  end else begin
                     square_start_y <= square_start_y - 1;
                     if(square_start_y == 0) begin
                        square_vector_y <= 0;
                        square_start_y <= square_start_y + 1;
                     end
                  end
               end
            end
         end
      end
   end

endmodule
