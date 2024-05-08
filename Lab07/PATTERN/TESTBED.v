`timescale 1ns/1ps
`include "PATTERN.v"
//`include "../00_TESTBED/PATTERN_other.v"
//`include "../00_TESTBED/PATTERN_HUANG.v"
`ifdef RTL
`include "MM_TOP.v"
`elsif GATE
`include "MM_TOP_SYN.v"
`endif

module TESTBED();


wire	    clk1, clk2;
wire        rst_n;
wire        in_valid;
wire [3:0] in_matrix_A;
wire [3:0] in_matrix_B;
wire 	    out_valid;
wire [7:0] out_matrix;

initial begin
  `ifdef RTL
    $fsdbDumpfile("MM_TOP.fsdb");
	$fsdbDumpvars(0,"+mda");
  `elsif GATE
    //$fsdbDumpfile("MM_TOP.fsdb");
	$sdf_annotate("MM_TOP_SYN_pt.sdf",I_MM,,,"maximum");      
	//$fsdbDumpvars(0,"+mda");
  `endif
end

MM_TOP I_MM
(
  // Input signals
	.clk1(clk1),
	.clk2(clk2),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_matrix_A(in_matrix_A),
	.in_matrix_B(in_matrix_B),
  // Output signals
	.out_valid(out_valid),
	.out_matrix(out_matrix)
);


PATTERN I_PATTERN
(
  // Output signals
	.clk1(clk1),
	.clk2(clk2),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_matrix_A(in_matrix_A),
	.in_matrix_B(in_matrix_B),
  // Input signals
	.out_valid(out_valid),
	.out_matrix(out_matrix)
);

endmodule