//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 SPRING
//   Lab04 Exercise		: Convolution Neural Network
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
  `include "PREFIX.v"
`endif
`ifdef GATE
  `include "PREFIX_SYN.v"
`endif

	  		  	
module TESTBED;

wire          clk, rst_n, in_valid;
wire          opt;
wire  [4:0]   in_data;
wire          out_valid;
wire  [94:0]  out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("PREFIX.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("PREFIX_SYN.sdf", u_PREFIX);
    $fsdbDumpfile("PREFIX_SYN.fsdb");
    $fsdbDumpvars();    
  `endif
end

`ifdef RTL
PREFIX u_PREFIX(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .opt(opt),
    .in_data(in_data),
    .out_valid(out_valid),
    .out(out)
    );
`endif

`ifdef GATE
PREFIX u_PREFIX(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .opt(opt),
    .in_data(in_data),
    .out_valid(out_valid),
    .out(out)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .opt(opt),
    .in_data(in_data),
    .out_valid(out_valid),
    .out(out)
    );
  
endmodule
