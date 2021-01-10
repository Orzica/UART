module xfda_baud_gen(clk,reset,baud_rate
    );
	input  clk , reset ;
	output baud_rate ;
	
	assign baud_rate = bd ;
	
	always @(posedge clk ) begin
		if ( reset ) 	
			count <= 14'b0 ;
		else if ( count == 14'b10100010101111 ) 
			count <= 14'b0 ;

endmodule
