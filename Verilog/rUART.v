module xfda_trans(clk,ok,reset,data_in,Tx,enable
    );
	 input clk , reset , enable , ok  ;
	 input [111:0] data_in ;
	 output Tx ;
	 
	 reg         data_reg ;
	 reg [7:0]   saved_data   = 8'b0 ;
	 reg [13:0]  count        = 14'b0 ;
	 reg [3:0]   idx          = 4'b0 ;
	 reg [1:0]   state        = 2'b0 ;
	 reg         trs_enable   = 1'b0 ;
	 reg [41:0]  count_enable = 42'b0 ;
	 reg [7:0]   salveaza     = 8'b0 ;
	 reg [111:0] shift        = 112'b0 ;
	 
	 parameter [1:0] idle      = 2'b0 ;
	 parameter [1:0] start     = 2'b01 ;
	 parameter [1:0] send_data = 2'b10 ;
	 parameter [1:0] stop      = 2'b11 ;
	 
	 wire  baud_generator ;
	 
	 baud_rate_gen b1(.clk(clk),.reset(reset),.enable(enable),.baud_gen(baud_generator)) ;
	 
	 
	 assign  Tx = data_reg ;
	 
	 
	 always @(posedge clk) begin
		if ( enable == 1'b0 )
			count_enable <= 42'b0 ;
		else
			count_enable <= count_enable + 1'b1 ;
		if ( count_enable == 42'b000000000000000000000000000000000000000001 )
			trs_enable <= 1'b1 ;
		else
			trs_enable <= 1'b0 ;
	 end
			
	 always @(posedge clk) begin	
		if ( ok )
			shift[111:0] <= data_in[111:0] ; 
		if ( reset ) begin
			data_reg <= 1'b1 ;
			state <= idle ;
			saved_data <= 8'b0 ;
			idx <= 4'b0 ;
		end else 
			case ( state ) 
			idle : begin
				data_reg <= 1'b1 ;
				if( trs_enable) begin
					state <= start ;
					shift[111:0] <= {8'b0,shift[111:8]} ;
					saved_data <= shift[7:0] ;
				end else
					state <= idle ;
				end
			start : begin
				data_reg <= 1'b0 ;
				if ( baud_generator )
					state <= send_data ;
				else 
					state <= start ;
				end
			send_data : begin
				if ( idx == 4'b1000 ) begin
					state <= stop ;
					idx <= 1'b0 ;
				end else begin
				data_reg <= saved_data[0] ;
					if( baud_generator ) begin
						idx <= idx + 1'b1 ;
						saved_data <= { 1'b0 , saved_data[7:1] } ;
					end else 						
						state <= send_data ;					
					end
				end
			stop : begin
				data_reg <= 1'b1 ;	
				if(baud_generator) 
					state <= idle ;
				end
			default : state <= idle ;
			endcase 
		end	

endmodule

