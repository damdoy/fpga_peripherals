//memory module i got from my ice40 exmaples repo (https://github.com/damdoy/ice40_ultraplus_examples)
//which will sythesize into a BRAM
module bram(input wire clk, input wire rd_en, input wire wr_en, input wire [6:0] rd_addr, input wire [6:0] wr_addr, input wire [47:0] data_in, output reg [47:0] data_out, output reg valid_out);

   reg [47:0] memory [0:83];
   integer i;

   initial begin
      valid_out = 0;
   end

   always @(posedge clk)
   begin
      // default
      valid_out <= 0;

      if(wr_en) begin
         memory[wr_addr] <= data_in;
      end
      if (rd_en) begin
         data_out <= memory[rd_addr];
         valid_out <= 1;
      end
   end
endmodule
