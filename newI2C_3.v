module newI2C_3 (
input clk,
     input reset_n,        
     output [7:0] data_tx,  //data read from slave
	 output bit,
	 output reg led, 
    inout reg sda,       
    inout  scl   ); 
	 
	
	 

reg				GO; 														//flag to start our i2c write operation
reg 				[6:0] SD_COUNTER=0; 										//counter to keep track of													
reg	[9:0]		COUNT; 	
reg 				SCLK; 


	 localparam ready0=0, ready=1,
	 start0=2,
	 start=3, 
	 start1=4,
	 command=5, slv_ack1=6,
	 ack2=7,slv_ack3=8,
	 adr_point_0=9,
	 adr_point =10,
	
	 wr0=11,
	 wr1=12,
	 
	 wr2=15,
	 wr3=16,
	 slv_ack4=13,
	 stop1=14,
	
	 
	 start2=17,
	 adr1=18,
	 ack3=19,
	 adr2=20,
	 ack4=21,
	 stop2=22,
	 stop3=23,
	 stop4=24;
	 
	 reg [7:0] addr = 8'b10010000;
	 reg [6:0] data_wr;
	 reg [6:0] state;
	 reg data_clk=0;     		//data clock for sda
	 reg data_clk_prev; 		// data clock during previous system clock
	 reg scl_clk =1;       		// constantly running internal scl
		
    reg [7:0] addr_rw;      // latched in address and read/write
	 //wire [7:0] data_tx;       // latched in data to write to slave
	 reg [7:0] data_rd1= 8'b11000101; //10100011;
	 reg [7:0] data_rd2= 8'b10000011; //11000001
    //reg [7:0] data_rx;       //data received from slave
	 reg [2:0] bit_cnt = 7;									//tracks bit number in transaction
	 reg [4:0] bit_cnt_2=16;
	 reg [1:0]bit_1 =3 ;
	 reg [9:0] count=0; 			// timing for clock generation
	 reg [9:0] count_clk;
	 reg[4:0] bit_shift = 31;
	 reg [7:0]shift_reg;
	
	
	always@(posedge clk) COUNT <= COUNT + 1;

	
	assign bit=0;
	

	always @ (posedge COUNT[9] or negedge reset_n)
		begin
		if (!reset_n)
			GO <= 0;
		else
			GO <= 1;
		end
	
	
	always @(posedge COUNT[9] or negedge reset_n) 
		begin
			if (!reset_n) begin
				SD_COUNTER <= 6'b0;
				end
			else
			begin
			if (!GO) 
				SD_COUNTER <= 0;
			else 
				if (SD_COUNTER < 1000) 
					SD_COUNTER <= SD_COUNTER+1;
			
	end
end
	
	
	
	//assign data_tx = data_rd1;
	 
	assign scl =	((SD_COUNTER >= 3) & (SD_COUNTER <= 38) ) ? ~COUNT[9] : SCLK;//((SD_COUNTER >= 43) & (SD_COUNTER <= 60))) |((SD_COUNTER >= 32) & (SD_COUNTER <= 61)))
	
					
	
	
				always @( posedge COUNT[9] or negedge reset_n) 
					begin
						if (!reset_n) 
							begin 
								SCLK <= 1;
								//sda <= 1; 
								state<=ready0;
								bit_1 <=3; 
								end
						 else
					 
						 begin
							case (state)
							ready0:begin 
								 sda <= 1; 
								 state<=ready; end
							 ready: begin                       	//idle state
								//case (SD_COUNTER)
									 sda <= 0;
									                 		 
										 addr_rw <= addr;          
									 state <= start; 
									  end
							//start0: begin sda <= 0;
											//state <= start;
											//end
							 start : begin
											SCLK <= 0; state <= start1;
										end
							start1: begin			
											sda <= addr_rw[7];     //set first address bit to bus
											state <= command; 
											led<=0;
										end
									
							 command : begin                  //address and command byte of transaction
								if ((bit_cnt == 0)) begin
								 if (bit_1==3) begin
									 state <= slv_ack1;
									 bit_cnt <= 7;
									 end
									 else if ((bit_1==2)) begin
							    state<=ack2;
								 bit_cnt <= 7;
								 end
									 else if ((bit_1==1) )
										begin
									state <= slv_ack3;
									bit_cnt <= 7;
									end
												else 
												begin
									  state <= stop2;
									  bit_cnt <= 7;
									  end
										end			
									                 //go to slave acknowledge (command)
									 	
								else                        	     //next clock cycle of command state
									begin
									 bit_cnt <= bit_cnt - 1;        //keep track of transaction bits
									 sda <= addr_rw[bit_cnt-1]; //write address/command bit to bus
									 state <= command;              //continue with command
									end
								end
								
							  slv_ack1 : begin if(sda == 0)
											begin
									
										bit_cnt<=7;
										addr_rw <= 8'b00000001;
										state <= command;//adr_point_0;
										bit_1<= bit_1-1;
										
										end
										else
										state<=stop2;
								//else state<=ready0;
									end
									
							/*adr_point_0	: begin
										addr_rw <= 8'b00000001;
										sda <= addr_rw[7]; 
										state <= adr_point;
										end
										
							 adr_point: begin
										 if (bit_cnt==0) begin
										 bit_cnt <= 7;
										 state <=ack2;
										   end
										else begin	
										 bit_cnt <= bit_cnt - 1; 
										 sda <= addr_rw[bit_cnt-1];   //write first bit of data
										  state<= adr_point;              
										end
									                  //go to read byte
										end*/
																		
								ack2: begin                    //slave acknowledge bit (command)
									//if(sda == 0)        		  //write command
												//begin
										led<=1;
										bit_cnt<=7;
										
										addr_rw <= data_rd1[bit_cnt];
										state <= command;
										bit_1<= bit_1-1;
										end
										
									//else state<= stop2;
										//end
								/*wr0	: begin
										sda <= data_rd1[7];
										led<=1;
										state <= wr1;
										 end
								wr1: begin                  				//master acknowledge bit after a read
										if (bit_cnt == 0)              //write byte transmit finished
										  begin
											bit_cnt <= 7;                 //reset bit counter for "byte" states
											state <= slv_ack3;            //go to slave acknowledge (write)
										  end
										 else                             //next clock cycle of write state
										  begin
											bit_cnt <= bit_cnt - 1;        //keep track of transaction bits
											sda <= data_rd1[bit_cnt-1]; //write next bit to bus
											state <= wr1;                   //continue writing
										  end*/
										
										
										
								slv_ack3: begin                      //slave acknowledge bit (write)
										    // if(sda == 0)        		  //write command
												//begin
													bit_cnt<=7;
													addr_rw <= data_rd2[bit_cnt];
													state <= command;
													led<=0;
													bit_1<= bit_1-1;
												end
												//else
												//state <= stop2;                  //go to stop bit
								//	end
									
								/*wr2: begin sda <= data_rd2[bit_cnt];
												state <= wr3;
												end
						
								wr3 : begin                  				//master acknowledge bit after a read
										if (bit_cnt == 0)              //write byte transmit finished
										  begin
											bit_cnt <= 7;                 //reset bit counter for "byte" states
											state <= slv_ack4;            //go to slave acknowledge (write)
										  end
										 else                             //next clock cycle of write state
										  begin
											bit_cnt <= bit_cnt - 1;        //keep track of transaction bits
											sda <= data_rd2[bit_cnt-1]; //write next bit to bus
											state <= wr3;                   //continue writing
										  end
										end 	
								slv_ack4: begin                       //slave acknowledge bit (write)
										     if(sda == 0)   begin     		  //write command
												state <= stop1;
												//led<=0;
											    end	
												else
												state <= start;                  //go to stop bit
									end*/
									
									
								stop1: begin                      		//stop bit of transaction
										
										 sda <= 1'b0; SCLK <= 1'b1; 
										
										//bit_cnt<=7;
										//addr_rw<=8'b10010001; 
										state <= stop2; end              
									
							/*	start0: begin	sda <= 1'b1;
								         state <= start1; end
											
								start1: begin	sda <= 1'b0;
											state <= start2; end
								start2: begin
										SCLK <= 1'b0;
										sda <= addr_rw[bit_cnt];     //set first address bit to bus
										state <= adr1; 
									  end						
								adr1: begin
										 if (bit_cnt==0) begin
										 bit_cnt <= 7;
										 state <=ack3;
										   end
										else begin	
										 bit_cnt <= bit_cnt - 1; 
										 sda <= addr_rw[bit_cnt];   //write first bit of data
										  state<= adr1;              
										end
											end
								ack3: begin                       //slave acknowledge bit (write)
										     if(sda == 0)        		  //write command
												begin
													bit_cnt<=7;
													state <= adr2;
												end
												else
												state <= start;                  //go to stop bit
									end
									
								adr2:begin
										 if (bit_cnt==0) begin
										 bit_cnt <= 7;
										 sda<=0;
										 state <=ack4;								 
										   end
										else begin	
										 bit_cnt <= bit_cnt - 1; 
										 shift_reg  <= {sda,shift_reg[7:1]};   //write first bit of data
										  state<= adr2;              
										end
										end
								 ack4: begin                       //slave acknowledge bit (write)
										    if (bit_cnt==0) begin
										 bit_cnt <= 7;
										 sda<=0;
										 state <= stop2;
										
										   end
										else begin	
										 bit_cnt <= bit_cnt - 1; 
										 shift_reg  <= {sda,shift_reg[7:1]};   //write first bit of data
										  state<= adr2;              
										end 
										end*/
								
							   stop2 : begin                      		//stop bit of transaction
										 
										 sda <= 1'b0; SCLK <= 1'b1;
										 state <=stop3;SCLK <= 1'b1; end	
								stop3 : begin
										sda <= 1'b1; SCLK <= 1'b1;end
									   //state <=stop4;	end
								/*stop4 : begin sda <= 0; //start
										 SCLK <= 0;
										bit_cnt<=7;
										addr_rw<=8'b10010001; 
										state <= start2; end*/
										 
										endcase
									end              //go to idle state
										
										
									
						 										
							end
						
				
		  
		endmodule  