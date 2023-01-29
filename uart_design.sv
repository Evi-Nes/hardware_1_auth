`timescale 1ns/1ns

module baud_controller(reset, clk, baud_select, sample_ENABLE); 

input clk, reset;
input [2:0] baud_select;

output reg sample_ENABLE = 0;

reg[13:0] max_value;
reg[13:0] counter;

always@(baud_select)
begin
    case(baud_select)
        3'b000:max_value = 10417; // 10^9 / (300 * 16 * 20) We sample 300 bits per second (10^9 nanoseconds, with 16 samples per bit, 
        3'b001:max_value = 2604;
        3'b010:max_value = 651;
        3'b011:max_value = 326;
        3'b100:max_value = 163;
        3'b101:max_value = 81;
        3'b110:max_value = 54;
        3'b111:max_value = 27;
    endcase
end

  always@(posedge clk or posedge reset)
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

module uart_transmitter(give_reset, give_clk, Tx_DATA, baud_select, Tx_WR, TX_EN, TxD, TX_BUSY);
input give_clk, give_reset;
input [2:0] baud_select;

input [7:0] Tx_DATA; // Incoming 8-bit data to transmit
input TX_EN; // Enables the transmitter. Should be on while transmission is in progress
input Tx_WR; // Write the input data to Tx_DATA, when Tx_WR is pulsed for one cycle

output reg TxD = 1; // Transmit data output
output reg TX_BUSY;  // Whether the device is busy, set to 1 once transmission starts, set to 0 once transmission ends

reg [3:0] counter;
reg [3:0] bitIndex = 0;
wire Tx_sample_ENABLE;
reg mes_end = 0 ;

baud_controller baud_controller_tx_instance (give_reset, give_clk, baud_select, Tx_sample_ENABLE);

reg [2:0] current_state, next_state;
  reg [2:0] IDLE = 3'b000, TSTART = 3'b001, TDATA = 3'b010, TPARITY = 3'b011, TSTOP = 3'b100;

always @(posedge Tx_sample_ENABLE or posedge give_reset)
begin
    if (give_reset)
    begin 
        current_state <= IDLE;
    end
    else
    begin
        current_state <= next_state;
    end
end
  
  always@(current_state or TX_EN or Tx_WR or counter)
begin 
    case(current_state)
        IDLE:
            if(TX_EN==1 && Tx_WR==0)
            begin
                next_state = TSTART;
            end
            else
              begin
                next_state = IDLE;
              end

      	TSTART:
          if(counter == 15)
            begin
                next_state = TDATA;
            end

        TDATA:
          if(counter == 15 && bitIndex < 7) 
            begin
                next_state = TDATA;
            end
      else if(counter == 15)
       		begin
                next_state = TPARITY;
        	end

        TPARITY:
          if(counter == 15)
            begin
                next_state = TSTOP;
            end

        TSTOP:
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

        TSTART:
//           if (counter == 1)
          begin
              TX_BUSY = 1;
              TxD = 0;
              bitIndex = 0;
          end

        TDATA:
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

        TPARITY:
          //if(counter == 1)
            begin
                TxD = ^Tx_DATA;
            end

        TSTOP:
           //if(counter == 1)
            begin
              TxD = 1;
              TX_BUSY = 0;
            end
    endcase
end

always@(posedge Tx_sample_ENABLE or posedge give_reset)
begin
    if(give_reset || counter == 15)
    begin
        counter = 0;
    end
    else
    begin
        counter = counter + 1;
    end
end

endmodule


module uart_receiver(give_reset, give_clk, Rx_DATA, baud_select, RX_EN, RxD, Rx_FERROR, Rx_PERROR, Rx_VALID);
input give_clk, give_reset;
input [2:0] baud_select;
input RX_EN;
  
input reg RxD;
output reg[7:0] Rx_DATA;
output reg Rx_FERROR; // Framing Error //
output reg Rx_PERROR; // Parity Error //
output reg Rx_VALID; // Rx_DATA is Valid //

reg [3:0] counter;
reg [3:0] bitIndex = 7;
wire Rx_sample_ENABLE;
reg mes_end = 0 ;
reg expected_parity = 0;
  
baud_controller baud_controller_rx_instance(give_reset, give_clk, baud_select, Rx_sample_ENABLE);

reg [2:0] current_state, next_state;
  reg [2:0] IDLE = 3'b000, TSTART = 3'b001, TDATA=3'b010 , TVALIDATE=3'b011, TSTOP=3'b100;
  
  always @(posedge Rx_sample_ENABLE or posedge give_reset)
begin
    if (give_reset)
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
                next_state = TSTART;
            end
            else
              begin
                next_state = IDLE;
              end
      
      	TSTART:
           if(counter == 15)
            begin
                next_state = TDATA;
            end
          
        TDATA:
          if(counter == 15 && bitIndex > 0) 
            begin
                next_state = TDATA;
            end
      	else if(counter == 15)
       		begin
                next_state = TVALIDATE;
        	end
          
      TVALIDATE:
          if(counter == 15)
            begin
                next_state = TSTOP;
            end
      
         TSTOP:
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
      
  		 TSTART:
          begin
            bitIndex = 7;
          end
      
    	 TDATA:
           begin
           if(counter == 7)
            begin
              Rx_DATA[bitIndex] <= RxD;
              if (bitIndex == -1)
                begin
                bitIndex = 7;
                mes_end = 1;
                end
              else
                begin
                // bitIndex = bitIndex - 1;
            	end
              end
             if(counter == 15)
        	begin
          		bitIndex = bitIndex - 1;
        	end
           
           end
      
      	TVALIDATE:
          begin
            expected_parity = ^Rx_DATA;
            if(expected_parity != RxD)
              begin
                Rx_PERROR = 1;
              end
            end
      
      	TSTOP:
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
  
always@(posedge Rx_sample_ENABLE or posedge give_reset)
begin
    if(give_reset || counter == 15)
    begin
        counter = 0;
    end
    else
    begin
        counter = counter + 1;
    end
end

endmodule
