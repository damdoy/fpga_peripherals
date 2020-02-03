//todo parameters for clk calculation and fifo sizes
module uart(input clk_main, //clk of the system, should be larger than the target uart clk
            output tx_free, //indicates if there is space in the buffer to send uart byte
            input [7:0] tx_data, //data to send to uart
            input tx_data_valid, //assert the data to write
            output rx_available, //indicates that a byte was received and is in the buffer
            output reg[7:0] rx_data, //oldest non acknowledged received byte
            input rx_data_ack, //acknowledge the received byte, rx_data will contain the next one (or nothing if rx_available==0)
            output clk_uart_out, //clk for the uart tx, if needed for synchronous uart
            output reg uart_tx, //uart tx line
            input uart_rx); //uart rx line
   parameter FREQ_MAIN_HZ = 12000000;
   parameter FREQ_TARGET_UART_HZ = 9600;
   //amount of main clk before flipping the uart clk
   parameter HALF_UART_PERIOD = (FREQ_MAIN_HZ/FREQ_TARGET_UART_HZ)/2;

   reg [7:0] fifo_uart_tx [0:15];
   reg [3:0] fifo_uart_tx_head_write; //the element being writing to by main clk
   reg [3:0] fifo_uart_tx_head_read; //elem being read by uart clk

   reg start_sending;

   reg [7:0] fifo_uart_rx [0:15];
   reg [3:0] fifo_uart_rx_head_write; //the element being writing to by uart clk
   reg [3:0] fifo_uart_rx_head_read; //elem being read by main clk

   reg [19:0] clk_counter_tx;
   reg [19:0] clk_counter_rx;
   reg [4:0] rx_counter_bytes;
   reg rx_counting_bytes;
   reg [4:0] counter_uart_tx;
   reg [4:0] counter_uart_rx;

   reg clk_uart_tx;
   assign clk_uart_out = clk_uart_tx;

   //leave a 1-element margin of error just in case
   assign tx_free = (fifo_uart_tx_head_write != (fifo_uart_tx_head_read-2) );

   assign rx_available = (fifo_uart_rx_head_write != fifo_uart_rx_head_read) && !rx_data_ack;

   initial begin
      uart_tx = 0;

      fifo_uart_tx_head_write = 0;
      fifo_uart_tx_head_read = 0;
      fifo_uart_rx_head_write = 0;
      fifo_uart_rx_head_read = 0;

      start_sending = 0;

      clk_counter_tx = 0;
      clk_counter_rx = 0;
      rx_counting_bytes = 0;
      counter_uart_tx = 0;
      counter_uart_rx = 0;

      clk_uart_tx = 0;
   end

   always @(posedge clk_main)
   begin
      clk_counter_tx <= clk_counter_tx+1;

      rx_data <= fifo_uart_rx[fifo_uart_rx_head_read];

      if(clk_counter_tx == HALF_UART_PERIOD) begin
         clk_counter_tx <= 0;
         clk_uart_tx <= ~clk_uart_tx;
      end

      //check if space in fifo to start a read
      if(uart_rx == 0 && rx_counting_bytes == 0 && fifo_uart_rx_head_write != (fifo_uart_rx_head_read+1) ) begin
         rx_counting_bytes <= 1;
         rx_counter_bytes <= 0;
         clk_counter_rx <= HALF_UART_PERIOD2; //first read will happen at a half uart cycle
      end

      if(rx_counting_bytes == 1) begin
         clk_counter_rx <= clk_counter_rx + 1;
         if(clk_counter_rx == (HALF_UART_PERIOD*2)) begin
            rx_counter_bytes <= rx_counter_bytes + 1;
            clk_counter_rx <= 0;

            if(rx_counter_bytes >= 1 && rx_counter_bytes <= 8) begin
               fifo_uart_rx[fifo_uart_rx_head_write][rx_counter_bytes-1] <= uart_rx;
            end
            if(rx_counter_bytes == 9) begin
               if(uart_rx == 1) begin //ending bit well received, validate data in fifo, discarded otherwise
                  fifo_uart_rx_head_write <= fifo_uart_rx_head_write + 1;
               end
               rx_counting_bytes <= 0;
               rx_counter_bytes <= 0;
               clk_counter_rx <= 0;
            end
         end
      end

      //receive data from the module parent to send
      if(tx_data_valid == 1 && tx_free) begin
         fifo_uart_tx_head_write <= fifo_uart_tx_head_write+1;
         fifo_uart_tx[fifo_uart_tx_head_write] <= tx_data;
      end

      //acknowledge the current data, advance the fifo head
      if(rx_data_ack == 1 && (fifo_uart_rx_head_write != fifo_uart_rx_head_read) ) begin
         fifo_uart_rx_head_read <= fifo_uart_rx_head_read+1;
      end

   end

   //tx
   always @(posedge clk_uart_tx)
   begin
      //default uart is high
      uart_tx <= 1;

      if(start_sending == 1) begin
         counter_uart_tx <= counter_uart_tx + 1;
      end

      if(start_sending == 0 && fifo_uart_tx_head_write != fifo_uart_tx_head_read) begin
         start_sending <= 1;
      end

      //start bit only when start sending o/w will never have tx=1
      if(counter_uart_tx == 0 && start_sending == 1) begin
         uart_tx <= 0; //start bit
      end
      if(counter_uart_tx >= 1 && counter_uart_tx <= 8) begin
         uart_tx <= fifo_uart_tx[fifo_uart_tx_head_read][counter_uart_tx-1];
      end
      if (counter_uart_tx == 9) begin
         uart_tx <= 1; //end bit
         counter_uart_tx <= 0;
         start_sending <= 0;
         fifo_uart_tx_head_read <= fifo_uart_tx_head_read + 1;
      end
   end

endmodule
