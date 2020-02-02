`include "uart.v"

module top(input clk, output LED_R, output LED_G, output LED_B, input IOT_48B, output IOT_51A);

   wire UART_TX_PIN;
   wire UART_RX_PIN;

   assign IOT_51A = UART_TX_PIN;
   assign UART_RX_PIN = IOT_48B;

   reg [2:0] led;

   reg [31:0] main_counter; //counter to send data periodically
   reg [3:0] uart_send_val_counter; //incement char to send
   reg echo_uart;

   //uart module signals
   wire uart_tx_free;
   reg [7:0] uart_tx_data;
   reg uart_tx_data_valid;
   wire uart_rx_available;
   wire [7:0] uart_rx_data;
   reg uart_rx_data_ack;
   wire clk_uart_out;
   wire uart_tx;
   wire uart_rx;

   assign UART_TX_PIN = uart_tx;
   assign uart_rx = UART_RX_PIN;

   //breakout board clock seem to be 11.5MHz instead of 12
   uart #(.FREQ_MAIN_HZ(11500000), .FREQ_TARGET_UART_HZ(9600))
   uart_inst (
      .clk_main(clk), .tx_free(uart_tx_free), .tx_data(uart_tx_data), .tx_data_valid(uart_tx_data_valid), .rx_available(uart_rx_available), .rx_data(uart_rx_data), .rx_data_ack(uart_rx_data_ack),
      .clk_uart_out(clk_uart_out), .uart_tx(uart_tx), .uart_rx(uart_rx)
   );

   assign LED_R = ~led[0];
   assign LED_G = ~led[1];
   assign LED_B = ~led[2];

   initial begin
      led = 0;
      main_counter = 0;

      uart_tx_data_valid = 0;
      uart_send_val_counter = 0;
      echo_uart = 0;
   end

   always @(posedge clk)
   begin
      //defaults
      uart_tx_data_valid <= 0;
      uart_rx_data_ack <= 0;

      main_counter <= main_counter+1;
      if (main_counter[22:0] == 23'h400000) begin //a few times per second send a data
         if(uart_tx_free == 1) begin
            uart_tx_data <= 8'd65+uart_send_val_counter; //8'd65 = 'A'
            uart_tx_data_valid <= 1;
            uart_send_val_counter <= uart_send_val_counter + 1;
         end
      end

      if(uart_rx_available == 1 && echo_uart == 0) begin
         uart_rx_data_ack <= 1; //read next value in rx fifo
         if(uart_tx_free == 1) begin //send it back
            uart_tx_data <= uart_rx_data;
            uart_tx_data_valid <= 1;
         end
      end

   end

endmodule
