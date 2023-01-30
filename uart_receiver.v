`timescale 1ns/1ns

module uart_receiver(reset, clock, Rx_DATA, baud_select, RX_EN, RxD, Rx_FERROR, Rx_PERROR, Rx_VALID);
input clock, reset;
input [2:0] baud_select;
input RX_EN;
  
input reg RxD; // Incoming serial 
output reg[7:0] Rx_DATA;
output reg Rx_FERROR; // Framing Error //
output reg Rx_PERROR; // Parity Error //
output reg Rx_VALID; // Rx_DATA is has no framing or parity errors //

reg[7:0] Rx_RawDATA;
reg [3:0] counter;
reg [3:0] bitIndex = 7;
wire Rx_sample_ENABLE;
reg expected_parity = 0;
  
bit_reverse reverse(Rx_RawDATA, Rx_DATA);
baud_controller baud_controller_rx_instance(reset, clock, baud_select, Rx_sample_ENABLE);

reg [2:0] current_state, next_state;
  reg [2:0] IDLE = 3'b000, START = 3'b001, DATA = 3'b010, VALIDATE = 3'b011, STOP = 3'b100; // Define receiver's states

always @(posedge Rx_sample_ENABLE or posedge reset)
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
  
always@(current_state or RX_EN or counter)
begin 
    case(current_state)
        IDLE:
            if(RX_EN==1 && RxD == 0)
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
            if(counter == 15 && bitIndex > 0) 
            begin
                next_state = DATA;
            end
      	    else if(counter == 15)
       		begin
                next_state = VALIDATE;
        	end
          
        VALIDATE:
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
            Rx_FERROR = 0;
            Rx_PERROR = 0;
          	Rx_VALID = 0;
        end
      
  		START:
        begin
            bitIndex = 7;
        end
      
    	DATA:
        begin
            if(counter == 7)
            begin
                Rx_RawDATA[bitIndex] <= RxD;
                if (bitIndex == -1)
                begin
                    bitIndex = 7;
                end
            end
            if(counter == 15)
        	begin
          		bitIndex = bitIndex - 1;
        	end
        end
      
      	VALIDATE:
        begin
            expected_parity = ^Rx_RawDATA;
            if(expected_parity != RxD)
              begin
                Rx_PERROR = 1;
              end
        end
      
      	STOP:
        begin
            if( counter == 1 && RxD != 1)
            begin
                Rx_FERROR = 1;
            end
            
            if(Rx_FERROR || Rx_PERROR)
            begin
                Rx_VALID = 0;
            end
            else
            begin
                Rx_VALID = 1;
            end
        end
    endcase
end
  
always@(posedge Rx_sample_ENABLE or posedge reset) // Rx appropriate clock
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
