`timescale 1ns/1ns

module uart_transmitter(reset, clock, Tx_DATA, baud_select, Tx_WR, TX_EN, TxD, TX_BUSY);
input clock, reset;
input [2:0] baud_select;

input [7:0] Tx_DATA; // Incoming 8-bit data to transmit
input TX_EN; // Enables the transmitter. Should be on while transmission is in progress
input Tx_WR; // When Tx_WR is pulsed for one cycle, write the input data to Tx_DATA

output reg TxD = 1; // Serial data output
output reg TX_BUSY;  // set to 1 once transmission starts and the device is busy, set to 0 once transmission ends

reg [3:0] counter;
reg [3:0] bitIndex = 0;
wire Tx_sample_ENABLE;

baud_controller baud_controller_tx_instance (reset, clock, baud_select, Tx_sample_ENABLE);

reg [2:0] current_state, next_state;
reg [2:0] IDLE = 3'b000, START = 3'b001, DATA = 3'b010, PARITY = 3'b011, STOP = 3'b100; // Define transmitter's states.

always @(posedge Tx_sample_ENABLE or posedge reset)
begin
    if (reset)
    begin 
        current_state <= IDLE;
    end
    else
    begin
        current_state <= next_state;
    end
end
  
always@(current_state or TX_EN or Tx_WR or counter) // State Logic
begin 
    case(current_state)
        IDLE:
            if(TX_EN==1 && Tx_WR==0)
            begin
                next_state = START;
            end
            else
              begin
                next_state = IDLE;
              end

      	START:
          if(counter == 15)
            begin
                next_state = DATA;
            end

        DATA:
          if(counter == 15 && bitIndex < 7) 
            begin
                next_state = DATA;
            end
          else if(counter == 15)
       		begin
                next_state = PARITY;
        	end

        PARITY:
          if(counter == 15)
            begin
                next_state = STOP;
            end

        STOP:
          if(counter == 15)
            begin
                next_state = IDLE;
            end
    endcase
end

always@(current_state or counter) // Output Logic
begin
    case(current_state)
        IDLE:
        begin
            TX_BUSY = 0;
            TxD = 1;
        end

        START:
          begin
              TX_BUSY = 1;
              TxD = 0;
              bitIndex = 0;
          end

        DATA:
          begin
          if(counter == 0)
            begin
              TxD = Tx_DATA[bitIndex];
              if (bitIndex == 8)
                begin
                bitIndex = 0;
                end
           end
            if(counter == 15)
        	begin
          		bitIndex = bitIndex + 1;
        	end
          end

        PARITY:
            begin
                TxD = ^Tx_DATA;
            end

        STOP:
            begin
              TxD = 1;
              TX_BUSY = 0;
            end
    endcase
end

always@(posedge Tx_sample_ENABLE or posedge reset) // Tx appropriate clock
begin
    if(reset || counter == 15)
    begin
        counter = 0;
    end
    else
    begin
        counter = counter + 1;
    end
end

endmodule
