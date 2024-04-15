//###############################################################################################
//***********************************************************************************************
//    File Name   : SORT_IP_demo.v
//    Module Name : SORT_TP_demo
//***********************************************************************************************
//###############################################################################################


//synopsys translate_off   
`include "SORT_IP.v"
//synopsys translate_on

module SORT_IP_demo #(parameter IP_WIDTH = 8)(
	//Input signals
	IN_character, IN_weight,
	//Output signals
	OUT_character
);

// ======================================================
// Input & Output Declaration
// ======================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ======================================================
// Soft IP
// ======================================================
SORT_IP #(.IP_WIDTH(IP_WIDTH)) I_SORT_IP(.IN_character(IN_character), .IN_weight(IN_weight), .OUT_character(OUT_character)); 

endmodule