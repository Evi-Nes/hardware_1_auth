`timescale 1ns/1ns

module bit_reverse (Rx_DATA, Rx_REVERSEDDATA);
  input reg[7:0] Rx_DATA;
  output reg[7:0] Rx_REVERSEDDATA;
  
  always @* begin
    for (int i=0; i<8; i++) 
      Rx_REVERSEDDATA[i] = Rx_DATA[7-i];
  end
endmodule
