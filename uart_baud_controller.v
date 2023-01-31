`timescale 1ns/1ns

module baud_controller(reset, clock, baud_select, sample_ENABLE); 

input clock, reset;
input [2:0] baud_select;

output reg sample_ENABLE = 0;

reg[13:0] max_value;
reg[13:0] counter;

always@(baud_select)
begin
    case(baud_select)
        3'b000:max_value = 10417; // 10^9 / (300 * 16 * 20) We sample 300 bits per second (10^9 nanoseconds, with 16 samples per bit, and a clock period of 20 nanoseconds) 
        3'b001:max_value = 2604;
        3'b010:max_value = 651;
        3'b011:max_value = 326;
        3'b100:max_value = 163;
        3'b101:max_value = 81;
        3'b110:max_value = 54;
        3'b111:max_value = 27;
    endcase
end

always@(posedge clock or posedge reset)
    begin
      if(reset)
        begin
          counter = max_value;
          sample_ENABLE = 0;
        end
      else
        begin
          if(counter == 0)
            begin
              counter = max_value;
              sample_ENABLE = 1;
            end
          else
            begin
              sample_ENABLE = 0;
              counter = counter - 1;
            end
        end
    end

endmodule
