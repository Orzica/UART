module top_module(ok,clk,reset,enable,Tx,data_in_rx,end_rcv,led,show_me
    );
	input clk , reset , enable , data_in_rx, ok	;
	output Tx , show_me ;
	output end_rcv ;
	output [7:0] led ;
	
	
	//wire  baud_generator ;
	 
	 wire [111:0] plain_text ; 
	 
	xfda_reciv receptie(.clk(clk),.reset(reset),.data_in_rx(data_in_rx),.end_rcv(end_rcv),.led(led),.text_caracter(plain_text),.show_me(show_me));
	xfda_trans emisie(.ok(ok),.clk(clk),.reset(reset),.enable(enable),.data_in(plain_text),.Tx(Tx));
	
	
endmodule
