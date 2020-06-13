//using two SPRAM to represent the 128*128*16bits = 256Kb framebuffer
//each SPRAM is 128Kb, so the framebuffer fits perfecty in two of them
module screen_controller_memory(input wire clk, input wire rd_en, input wire wr_en, input wire [6:0] rd_addr_x, input wire [6:0] rd_addr_y,
                                input wire [6:0] wr_addr_x, input wire [6:0] wr_addr_y,
                                input wire [15:0] data_in, output reg [15:0] data_out, output reg valid_out
   );

   reg [12:0] ram_addr_0;
   reg [15:0] ram_data_in_0;
   wire [15:0] ram_data_out_0;
   reg [3:0] mask_wren_0;
   reg ram_wren_0;

   reg [12:0] ram_addr_1;
   reg [15:0] ram_data_in_1;
   wire [15:0] ram_data_out_1;
   reg [3:0] mask_wren_1;
   reg ram_wren_1;

   reg buf_rd_req;
   reg buf_select_spram;

   SB_SPRAM256KA spram0
   (
     .ADDRESS(ram_addr_0),
     .DATAIN(ram_data_in_0),
     .MASKWREN(mask_wren_0),
     .WREN(ram_wren_0),
     .CHIPSELECT(1'b1),
     .CLOCK(clk),
     .STANDBY(1'b0),
     .SLEEP(1'b0),
     .POWEROFF(1'b1),
     .DATAOUT(ram_data_out_0)
   );

   SB_SPRAM256KA spram1
   (
     .ADDRESS(ram_addr_1),
     .DATAIN(ram_data_in_1),
     .MASKWREN(mask_wren_1),
     .WREN(ram_wren_1),
     .CHIPSELECT(1'b1),
     .CLOCK(clk),
     .STANDBY(1'b0),
     .SLEEP(1'b0),
     .POWEROFF(1'b1),
     .DATAOUT(ram_data_out_1)
   );

   initial begin
      valid_out = 0;
   end

   always @(*)
   begin
      ram_addr_0 = {rd_addr_y[5:0], rd_addr_x[6:0]};
      ram_addr_1 = {rd_addr_y[5:0], rd_addr_x[6:0]};
      if (wr_en == 1) begin
         //select to which spram to write the data
         if(wr_addr_y[6] == 0) begin
            mask_wren_0 = 4'b1111;
            mask_wren_1 = 4'b0000;
            ram_wren_0 = 1;
            ram_wren_1 = 0;
         end else begin
            mask_wren_0 = 4'b0000;
            mask_wren_1 = 4'b1111;
            ram_wren_0 = 0;
            ram_wren_1 = 1;
         end
         ram_data_in_0 = data_in;
         ram_data_in_1 = data_in;
         ram_addr_0 = {wr_addr_y[5:0], wr_addr_x[6:0]};
         ram_addr_1 = {wr_addr_y[5:0], wr_addr_x[6:0]};
      end else if (wr_en == 0) begin
         ram_wren_0 = 0;
         ram_wren_1 = 0;
         mask_wren_0 = 4'b0000;
         mask_wren_1 = 4'b0000;
         ram_data_in_0 = 0;
         ram_data_in_1 = 0;
      end
   end

   always @(posedge clk)
   begin
      buf_rd_req <= rd_en;

      //keep indication which spram to read from
      buf_select_spram <= rd_addr_y[6];

      valid_out <= 0; //default

      if(buf_rd_req == 1) begin
         //select spram depending on address
         if(buf_select_spram == 0) begin
            data_out <= ram_data_out_0;
         end else begin
            data_out <= ram_data_out_1;
         end
         valid_out <= 1;
      end
   end
endmodule
