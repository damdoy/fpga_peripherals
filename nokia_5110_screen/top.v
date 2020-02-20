`include "screen_controller.v"

module top(output IOT_39A, output IOT_38B, output IOT_43A, output IOT_42B, output IOT_48B, output IOT_50B,
            output LED_R, output LED_G, output LED_B);

   //this include has its own init block, that's why it is here
   `include "screen_constant.v"

   parameter NB_COLUMNS = 84;

   wire clk_48mhz;
   wire clk_24mhz;
   reg clk_div;

   assign clk_24mhz = clk_div;

   reg SCE;
   reg RST;
   wire D_C;
   wire MOSI;
   wire SCLK;
   reg SCREEN_LED;

   assign IOT_39A = SCE;
   assign IOT_38B = RST;
   assign IOT_43A = D_C;
   assign IOT_42B = MOSI;
   assign IOT_48B = SCLK;
   assign IOT_50B = SCREEN_LED;

   //internal oscillators seen as modules
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );

   reg [2:0] led;

   reg [19:0] counter_start; //to put screen in reset for a while
   reg [23:0] counter_redraw;
   reg [6:0] shift_value; //will slowly shift what is written on the screen

   assign LED_R = ~led[0];
   assign LED_G = ~led[1];
   assign LED_B = ~led[2];

   reg [6:0] screen_controller_address; //84 lines ==> 7bit address
   reg [47:0] screen_controller_data;
   reg screen_controller_wr_en;
   reg screen_controller_enable;

   screen_controller screen_controller_inst(.clk_main(clk_24mhz), .address(screen_controller_address), .data(screen_controller_data),
      .wr_en(screen_controller_wr_en), .enable(screen_controller_enable),
      .spi_clk(SCLK), .spi_mosi(MOSI), .spi_d_c(D_C)
   );

   initial begin
      clk_div = 0;

      SCE = 0;
      RST = 0;
      LED = 0;

      led = 0;
      counter_start = 0;
      counter_redraw = 0;
      shift_value = 0;
      address_to_draw = 0;

      screen_controller_address = 0;
      screen_controller_data = 0;
      screen_controller_wr_en = 0;
      screen_controller_enable = 0;
   end

   always @ (posedge clk_48mhz) begin
      clk_div <= ~clk_div;
   end

   always @(posedge clk_24mhz)
   begin

      screen_controller_address <= 0;
      screen_controller_wr_en <= 0;

      if(counter_start < 20'h80000) begin //screen in reset mode
         counter_start <= counter_start + 1;
      end else begin //starts the screen
         RST <= 1;
         screen_controller_enable <= 1;
         counter_redraw <= counter_redraw + 1;

         //send screen pixels
         if(counter_redraw >= 23'h040000 && counter_redraw <= (23'h040000+(NB_COLUMNS-1))) begin
            screen_controller_address <= (counter_redraw[6:0]+shift_value);

            screen_controller_data <= SCREEN[(counter_redraw[6:2])]; //make each line in SCREEN 4bit wide
            screen_controller_wr_en <= 1;
         end
         if(counter_redraw == 23'h2fffff) begin //shift the scren by one pixel a few time per second
            counter_redraw <= 0;
            shift_value <= shift_value+1;
         end
      end
   end

endmodule
