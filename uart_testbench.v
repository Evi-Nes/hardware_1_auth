`timescale 10ns/10ns
`include "uart_receiver.v"
`include "uart_transmitter.v"
`include "uart_baud_controller.v"
`include "uart_bit_reverse.v"

module tb;

reg clock, reset;
reg[2:0] baud_select = 3'b111;

reg [7:0] Tx_DATA = 8'b11011101;
reg Tx_WR = 1;
reg TX_EN = 1;
wire TX_BUSY;

reg serial_wire;
reg [7:0] Rx_DATA;
reg RX_EN = 1;
reg Rx_FERROR, Rx_PERROR, Rx_VALID;

uart_transmitter transmitter(reset, clock, Tx_DATA, baud_select, Tx_WR, TX_EN, serial_wire, TX_BUSY);
uart_receiver receiver(reset, clock, Rx_DATA, baud_select, RX_EN, serial_wire, Rx_FERROR, Rx_PERROR, Rx_VALID);

initial begin
  	$dumpfile("dump.vcd");
  	$dumpvars;
    clock = 0;
    reset = 1;

    #20;
    reset = 0;

    case(baud_select) 
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

    case (baud_select) // Delay for message transfer
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

// Pulse clock with a period of 20ns
always #10 clock = ~ clock;

endmodule
