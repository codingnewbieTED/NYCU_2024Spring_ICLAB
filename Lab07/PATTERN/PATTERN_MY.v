`ifdef RTL
	`define CYCLE_TIME_clk1 47.1  //4.1ns, 7.1ns, 17.1ns, 47.1ns
    //`define CYCLE_TIME_clk1 4.1
    //`define CYCLE_TIME_clk1 7.1
    //`define CYCLE_TIME_clk1 17.1
	`define CYCLE_TIME_clk2 10.1
	`define PATNUM 1000
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
	`define PATNUM 1000
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

//================================================================
//  WIRE
//================================================================
real CYCLE1 = `CYCLE_TIME_clk1;
real CYCLE2 = `CYCLE_TIME_clk2;
integer i_pat,i,j;
integer latency,total_latency;
integer patcount = `PATNUM;
integer cnt_out;
reg [7:0] golden_matrix[0:15][0:15];
reg [3:0] in_A[0:15];
reg [3:0] in_B[0:15];
integer color_stage = 0, color, r = 5, g = 0, b = 0;
//================================================================
//  CLK
//================================================================
initial clk1 = 0;
always #(CYCLE1/2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE2/2.0) clk2 = ~clk2;

initial begin
	reset_task;
	total_latency = 0;
	for(i_pat=0;i_pat<patcount;i_pat = i_pat + 1)begin
		cnt_out = 0;
		input_generate;
		input_task;
		wait_finish;
		total_latency = total_latency + latency;
        case(color_stage)
        0: begin
            r = r - 1;
            g = g + 1;
            if(r == 0) color_stage = 1;
        end
        1: begin
            g = g - 1;
            b = b + 1;
            if(g == 0) color_stage = 2;
        end
        2: begin
            b = b - 1;
            r = r + 1;
            if(b == 0) color_stage = 0;
        end
    endcase
    color = 16 + r*36 + g*6 + b;


    $display("\033[38;5;%2dmPASS    PATTERN NO.%4d \033[00m | Latency:%4d", color, i_pat,latency);

		//$display("pass Pattern %d , latency = %d",i_pat,latency);
	end
	$display("Congratulations!");
    $display("Your execution cycles = %d cycles", total_latency);
    $display("Your clock period = %.1f ns", CYCLE1);
    $display("Total Latency = %.1f ns", total_latency * CYCLE1);
    $finish;
    $finish;
end


task reset_task;begin
	rst_n = 1;
	in_valid = 0;
	#(CYCLE1);
	force clk1 = 0;
	force clk2 = 0;
	rst_n = 0;
	#(CYCLE1 * 5);
	rst_n = 1;
	if(out_valid !== 0 || out_matrix !== 0) begin
		$display("ERROR signal reset!!! : out_valid = %d, out_matrix = %d",out_valid,out_matrix);
		$finish;
	end
	#(CYCLE1);
	release clk1;
	release clk2;
end endtask

task input_generate;begin
	for(i=0;i<16;i=i+1)begin
		in_A[i] = $urandom_range(0,15);
		in_B[i] = $urandom_range(0,15);
	end
	
	for(i=0;i<16;i=i+1)	
		for(j=0;j<16;j=j+1)
			golden_matrix[i][j] = in_A[i] * in_B[j];
end endtask

task input_task;begin
	repeat($random() % 3+1)@(negedge clk1);
	in_valid = 1;
	for(i=0;i<16;i=i+1)begin
		in_matrix_A = in_A[i];
		in_matrix_B = in_B[i];
		@(negedge clk1);
	end
	in_valid = 0;
	in_matrix_A = 'bx;
	in_matrix_B = 'bx;
end endtask

task wait_finish;begin
	latency = 0;
	while(cnt_out !== 256) begin
		if(latency == 5000) begin
			$display("ERROR: latency bigger than 5000!!!");
			$finish;
		end
		latency = latency + 1;
		@(negedge clk1);
	end
end endtask

always@(negedge clk1)begin
	if(out_valid) cnt_out <= cnt_out + 1;
end

always@(negedge clk1) begin
	if(out_valid)
		if(out_matrix !== golden_matrix[cnt_out/16][cnt_out%16]) begin
			$display("ERROR: out_matrix = %d, golden_matrix[%d][%d] = %d",out_matrix,cnt_out/16,cnt_out%16,golden_matrix[cnt_out/16][cnt_out%16]);
			$finish;
		end
	else if (!out_valid) begin
		if(out_matrix !== 0) begin
			$display("out_matrix should be zero when outvalid is low!!!");
			$finish;
		end
	end
end



endmodule
