`timescale 1ns / 1ps
`include "led_driver.v"

module tb;

reg give_clk,give_reset;
reg [3:0] char;
wire [6:0] LED;
wire an3, an2, an1, an0, a, b, c, d, e, f, g;

LEDdecoder decoder(char,LED); // instatiate decoder test
FourDigitLEDdriver driver(give_reset, give_clk, an3, an2, an1, an0, a, b, c, d, e, f, g);

initial begin
	give_clk = 0; // our clock is initialy set to 0
	give_reset = 1; // our reset signal is initialy set to 1

	#100; // after 100 timing units, i.e. ns
					
	give_reset = 0; // set reset signal to 0
					
	#10000 $finish;	 // after 10000 timing units, i.e. ns, finish our simulation
end
	
always #10 give_clk = ~ give_clk; // create our clock, with a period of 20ns

endmodule
