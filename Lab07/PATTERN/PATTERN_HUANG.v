`define PAT_NUM 1000

`ifdef RTL
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
`endif

module PATTERN(
	clk1,
	clk2,
	rst_n,
	in_valid,
	in_matrix_A,
	in_matrix_B,
	out_valid,
	out_matrix
);

output reg clk1, clk2;
output reg rst_n;
output reg in_valid;
output reg [3:0] in_matrix_A;
output reg [3:0] in_matrix_B;

input out_valid;
input [7:0] out_matrix;

///////////////////////////////////////////////////////////////////////

real cycle1 = `CYCLE_TIME_clk1;
real cycle2 = `CYCLE_TIME_clk2;

integer i, j;
integer i_pat;

integer latency;
integer total_latency;

reg [3:0] A [0:15];
reg [3:0] B [0:15];
reg [7:0] C [0:255];

///////////////////////////////////////////////////////////////////////

initial clk1 = 0;
initial clk2 = 0;
always #(cycle1/2.0) clk1 = ~clk1;
always #(cycle2/2.0) clk2 = ~clk2;

initial begin
    reset_signal_task;

    total_latency = 0;
    for (i_pat = 1; i_pat <= `PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        $display("PASS PATTERN %6d, LATENCY %4d", i_pat, latency);
        total_latency = total_latency + latency;
    end

    pass_task;
end

always @(negedge clk1) begin
    if (out_valid === 1'b0 && out_matrix !== 0)
        $fatal(1, "FAIL: OUT_MATRIX SHOULD BE ZERO WHEN OUT_VALID IS ZERO");
end

always @(*) begin
    if (in_valid === 1'b1 && out_valid === 1'b1)
        $fatal(1, "FAIL: IN_VALID CANNOT OVERLAP OUT_VALID");
end

//////////////////////////////////////////////////////////////////////

task reset_signal_task; 
begin 
    force clk1  = 1'b0;
    force clk2  = 1'b0;
    rst_n       = 1'b1;
    in_valid    = 1'b0;
    in_matrix_A = {4{1'bx}};
    in_matrix_B = {4{1'bx}};
    #(100);
    rst_n = 1'b0;
    #(100);
    if (out_valid !== 0 || out_matrix !== 0)
        $fatal(1, "FAIL: RESET");
    #(100);
    rst_n = 1'b1;
    #(100);
    release clk1;
    release clk2;
    #(100);
end 
endtask

task input_task; 
begin 
    repeat ($urandom_range(0, 3)) 
        @(negedge clk1);
    
    for (i = 0; i < 16; i = i + 1) begin
        A[i] = $urandom;
        B[i] = $urandom;
    end

    for (i = 0; i < 16; i = i + 1)
        for (j = 0; j < 16; j = j + 1)
            C[i*16+j] = A[i] * B[j];

    in_valid = 1'b1;
    for (i = 0; i < 16; i = i + 1) begin
        in_matrix_A <= A[i];
        in_matrix_B <= B[i];
        @(negedge clk1);
    end

    in_valid    = 1'b0;
    in_matrix_A = {4{1'bx}};
    in_matrix_B = {4{1'bx}};
end 
endtask

task wait_out_valid_task;
begin
    latency = 0;
    for (i = 0; i < 256; i = i + 1) begin
        while (out_valid !== 1'b1) begin
            if (latency == 4950)  // conservative. max latency in spec is 5000
                $fatal(1, "FAIL: LATENCY");
            @(negedge clk1);
            latency = latency + 1;
        end

        if (out_matrix !== C[i])
            $fatal(1, "FAIL: YOUR ANSWER IS INCORRECT");
        @(negedge clk1);
        latency = latency + 1;
    end
end
endtask

task pass_task;
begin
    $display("Congratulations!");
    $display("Your execution cycles = %d cycles", total_latency);
    $display("Your clock period = %.1f ns", cycle1);
    $display("Total Latency = %.1f ns", total_latency * cycle1);
    $finish;
end 
endtask

endmodule
