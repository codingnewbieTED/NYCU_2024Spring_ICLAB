//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2018 Fall
//   Lab02 Practice		: Complex Number Calculater
//   Author     		: Ping-Yuan Tsai (bubblegame@si2lab.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2018-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps


//`include "../00_TESTBED/PATTERN_ychuang_v1.v"
//`include "PATTERN.v"
//`include "../00_TESTBED/PATTERN.vp"
`include "../00_TESTBED/PATTERN_1.vp"
`ifdef RTL
  `include "CAD.v"
`endif
`ifdef GATE
  `include "CAD_SYN.v"
`endif
`ifdef POST
  `include "CHIP.v"
`endif

	  		  	
module TESTBED;

wire          clk, rst_n, in_valid, in_valid2;
wire          mode;
wire  [ 7:0]  matrix;
wire  [ 3:0]  matrix_idx;
wire  [ 1:0]  matrix_size;
wire          out_valid;
wire          out_value;


initial begin
  `ifdef RTL
//    $fsdbDumpfile("CAD.fsdb");
//	$fsdbDumpvars(0,"+mda");
//    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("CAD_SYN.sdf", u_CAD);
    //$fsdbDumpfile("CAD_SYN.fsdb");
    //$fsdbDumpvars();    
  `endif
  `ifdef POST
    $sdf_annotate("CAD_POST.sdf", u_CHIP);
    $fsdbDumpfile("CAD_POST.fsdb");
    $fsdbDumpvars();    
  `endif
end

`ifdef RTL
CAD u_CAD(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .mode(mode),
    .matrix_size(matrix_size),
    .matrix(matrix),
    .matrix_idx(matrix_idx),
    .out_valid(out_valid),
    .out_value(out_value)
    );
`endif

`ifdef GATE
CAD u_CAD(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_valid2(in_valid2),
    .mode(mode),
    .matrix(matrix),
    .matrix_size(matrix_size),
    .matrix_idx(matrix_idx),
    .out_valid(out_valid),
    .out_value(out_value)
    );
`endif

`ifdef POST
CHIP u_CHIP(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_valid2(in_valid2),
    .mode(mode),
    .matrix(matrix),
    .matrix_size(matrix_size),
    .matrix_idx(matrix_idx),
    .out_valid(out_valid),
    .out_value(out_value)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .mode(mode),
    .matrix(matrix),
    .matrix_size(matrix_size),
    .matrix_idx(matrix_idx),
    .out_valid(out_valid),
    .out_value(out_value)
    );
  
 
endmodule
