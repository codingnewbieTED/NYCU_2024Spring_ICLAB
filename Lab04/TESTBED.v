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

//`include "PATTERN.v"
`include "../00_TESTBED/PATTERN.vp"
//`include "../00_TESTBED/PATTERN_MY_2023.v"
//`include "../00_TESTBED/PATTERN_MY.v"
//   `include "../00_TESTBED/PATTERN_ychuang_v1.v"
//`include "../00_TESTBED/PATTERN_3.v"
//`include "../00_TESTBED/PATTERN_Lab04_Winnie_Pooh.v"
`ifdef RTL
  `include "CNN.v"
`endif
`ifdef GATE
  `include "CNN_SYN.v"
`endif

	  		  	
module TESTBED;

wire          clk, rst_n, in_valid;
wire  [31:0]  Img;
wire  [31:0]  Kernel;
wire  [31:0]  Weight;
wire  [ 1:0]  Opt;
wire          out_valid;
wire  [31:0]  out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("CNN.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("CNN_SYN.sdf", u_CNN);
    //$fsdbDumpfile("CNN_SYN.fsdb");
    //$fsdbDumpvars();    
  `endif
end

`ifdef RTL
CNN u_CNN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
`endif

`ifdef GATE
CNN u_CNN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Img(Img),
    .Kernel(Kernel),
    .Weight(Weight),
    .Opt(Opt),
    .out_valid(out_valid),
    .out(out)
    );
  
 
endmodule
