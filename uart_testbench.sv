`timescale 1ns/1ns

module tb;

reg give_clk, give_reset;
reg[2:0] baud_select = 3'b111;

reg [7:0] Tx_DATA = 8'b11011101;
reg Tx_WR = 1;
reg TX_EN = 1;
wire TxD;
wire TX_BUSY;

reg [7:0] Rx_DATA;
reg RX_EN = 1;
reg Rx_FERROR, Rx_PERROR, Rx_VALID;

// uart test(give_reset, give_clk, Tx_DATA, baud_select, Tx_WR, TX_EN, TxD, TX_BUSY, Rx_DATA, RX_EN, TxD, Rx_FERROR, Rx_PERROR, Rx_VALID);
uart_transmitter transmitter(give_reset, give_clk, Tx_DATA, baud_select, Tx_WR, TX_EN, TxD, TX_BUSY);
uart_receiver receiver(give_reset, give_clk, Rx_DATA, baud_select, RX_EN, RxD, Rx_FERROR, Rx_PERROR, Rx_VALID);
  
initial begin
  	$dumpfile("dump.vcd");
  	$dumpvars;
    give_clk = 0;
    give_reset = 1;

    #20;
    give_reset = 0;

    case(baud_select) // Why * 20?
        3'b000: #(10417*20);
        3'b001: #(2604*20);
        3'b010: #(651*20);
        3'b011: #(326*20);
        3'b100: #(163*20);
        3'b101: #(81*20);
        3'b110: #(54*20);
        3'b111: #(27*20);
    endcase

    Tx_WR = 0;

    case (baud_select) // Why the multiplication? // Delay for message transfer
        3'b000: #(10417*20*16*11);
        3'b001: #(2604*20*16*11);
        3'b010: #(651*20*16*11);
        3'b011: #(326*20*16*11);
        3'b100: #(163*20*16*11);
        3'b101: #(81*20*16*11);
        3'b110: #(54*20*16*11);
        3'b111: #(27*20*16*11);
    endcase

    #10000 $finish;	 // after 10000 timing units, i.e. ns, finish our simulation
end

// Add clock with a period of 20ns
always #10 give_clk = ~ give_clk;

endmodule
