//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
// Copyright (c) 2023, SI2 Lab
// MODULE    : TESTBED
// FILE NAME : TESTBED.v
// VERSRION  : 1.0
// DATE      : Feb. 2, 2024
// AUTHOR    : YI-XUAN RAN, NYCU IEE
// CODE TYPE : RTL or Behavioral Level (Verilog)
//  
//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`timescale 1ns/1ps

// PATTERN
`include "PATTERN.v"
// DESIGN
`ifdef RTL
	`include "ENIGMA.v"
`elsif GATE
	`include "../02_SYN/Netlist/ENIGMA_SYN.v"
`endif


module TESTBED();

wire clk;
wire rst_n;
wire in_valid, in_valid_2;
wire crypt_mode;
wire out_valid;

wire [6-1:0] code_in;
wire [6-1:0] out_code;


initial begin
  `ifdef RTL
    $fsdbDumpfile("ENIGMA.fsdb");
		$fsdbDumpvars(0, "+mda");
	`elsif GATE
	  $fsdbDumpfile("ENIGMA_SYN.fsdb");
		$fsdbDumpvars(0, "+mda");
		$sdf_annotate("../02_SYN/Netlist/ENIGMA_SYN.sdf", I_ENIGMA); 
	`endif
end

ENIGMA I_ENIGMA
(
	  // Input signals
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_valid_2(in_valid_2),
    .crypt_mode(crypt_mode),
    .code_in(code_in),

    // Output signals
    .out_valid(out_valid), 
	  .out_code(out_code)
  
);

PATTERN I_PATTERN
(
	  // Output signals
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_valid_2(in_valid_2),
    .crypt_mode(crypt_mode),
    .code_in(code_in),
    
    // Input signals
    .out_valid(out_valid), 
	  .out_code(out_code)
);

endmodule
