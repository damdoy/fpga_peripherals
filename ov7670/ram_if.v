//128KB memory from 4spram
module ram_if(input clk, input [16:0] address, input [15:0] data_in, input write_en, output [15:0] data_out);

   wire spram_write_en_0;
   wire spram_write_en_1;
   wire spram_write_en_2;
   wire spram_write_en_3;

   wire [15:0] spram_data_out_0;
   wire [15:0] spram_data_out_1;
   wire [15:0] spram_data_out_2;
   wire [15:0] spram_data_out_3;

   SB_SPRAM256KA spram0
   (
      .ADDRESS(address[14:1]),
      .DATAIN(data_in),
      .MASKWREN({spram_write_en_0, spram_write_en_0, spram_write_en_0, spram_write_en_0}),
      .WREN(spram_write_en_0),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(spram_data_out_0)
   );

   SB_SPRAM256KA spram1
   (
      .ADDRESS(address[14:1]),
      .DATAIN(data_in),
      .MASKWREN({spram_write_en_1, spram_write_en_1, spram_write_en_1, spram_write_en_1}),
      .WREN(spram_write_en_1),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(spram_data_out_1)
   );

   SB_SPRAM256KA spram2
   (
      .ADDRESS(address[14:1]),
      .DATAIN(data_in),
      .MASKWREN({spram_write_en_2, spram_write_en_2, spram_write_en_2, spram_write_en_2}),
      .WREN(spram_write_en_2),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(spram_data_out_2)
   );

   SB_SPRAM256KA spram3
   (
      .ADDRESS(address[14:1]),
      .DATAIN(data_in),
      .MASKWREN({spram_write_en_3, spram_write_en_3, spram_write_en_3, spram_write_en_3}),
      .WREN(spram_write_en_3),
      .CHIPSELECT(1'b1),
      .CLOCK(clk),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1),
      .DATAOUT(spram_data_out_3)
   );

   //combinational
   always @(*)
   begin
      spram_write_en_0 <= 0;
      spram_write_en_1 <= 0;
      spram_write_en_2 <= 0;
      spram_write_en_3 <= 0;

      if(address[16:15] == 0) begin
         data_out <= spram_data_out_0;
         spram_write_en_0 <= write_en;
      end else if(address[16:15] == 1) begin
         data_out <= spram_data_out_1;
         spram_write_en_1 <= write_en;
      end else if(address[16:15] == 2) begin
         data_out <= spram_data_out_2;
         spram_write_en_2 <= write_en;
      end else if(address[16:15] == 3) begin
         data_out <= spram_data_out_3;
         spram_write_en_3 <= write_en;
      end
   end

   always @(posedge clk)
   begin
   end

endmodule
