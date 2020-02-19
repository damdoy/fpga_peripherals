reg [47:0] SCREEN [20:0]; //21 rows 4 pixel wide to maxe 84 pix width

integer i;
initial begin
   for (i=0; i<=83; i=i+1)begin
      SCREEN[i] = 48'h000000000000;
   end

   //draws "ice40"
   SCREEN[00] =  48'h000000000000;
   SCREEN[01] =  48'h000000000000;
   SCREEN[02] =  48'h0ffffffffff0;
   SCREEN[03] =  48'h000000000000;
   SCREEN[04] =  48'h0ffffffffff0;
   SCREEN[05] =  48'h0ff000000ff0;
   SCREEN[06] =  48'h000000000000;
   SCREEN[07] =  48'h0ffffffffff0;
   SCREEN[08] =  48'h0ff00ff00ff0;
   SCREEN[09] =  48'h000000000000;
   SCREEN[10] =  48'h000000000000;
   SCREEN[11] =  48'h000000000000;
   SCREEN[12] =  48'h000000fffff0;
   SCREEN[13] =  48'h000000ff0000;
   SCREEN[14] =  48'h0ffffffffff0;
   SCREEN[15] =  48'h000000000000;
   SCREEN[16] =  48'h0ffffffffff0;
   SCREEN[17] =  48'h0ff000000ff0;
   SCREEN[18] =  48'h0ffffffffff0;
   SCREEN[19] =  48'h000000000000;
   SCREEN[20] =  48'h000000000000;
end
