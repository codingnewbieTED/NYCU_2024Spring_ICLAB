//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME 10

module PATTERN(
    // Input Ports
    clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 

    // Output Ports
    out_code, 
	out_valid
);

// ===============================================================
// Input to design
// ===============================================================
output reg clk;   
output reg rst_n;
output reg in_valid;
output reg in_valid_2;        
output reg crypt_mode;
output reg [6-1:0] code_in;	
// ===============================================================
// Output to pattern
// ===============================================================
input         out_valid;
input [6-1:0] out_code;

// ===============================================================
// Parameter and Integer
// ===============================================================
parameter CYCLE_DELAY = 100;
parameter TEXT_SIZE = 300;
integer PAT_NUM = 100;
integer i_pat, i, j, a, t;
integer latency;
integer total_latency;
integer f_rotorA, f_rotorB, f_in, f_out;

// INPUT
reg crypt_mode_reg;
reg [6-1:0] text [0:TEXT_SIZE-1];
reg [6-1:0] rotorA_table [0:64-1];
reg [6-1:0] rotorB_table [0:64-1];
reg [6-1:0] code_last;      // for record the code_in previous
integer str_size;
integer flag;

// OUTPUT
integer fout;
integer out_idx;
integer total_error;
reg [6-1:0] golden [0:TEXT_SIZE-1];
reg [8-1:0] golden_ascii [0:TEXT_SIZE-1];
reg [8-1:0] text_ascii [0:TEXT_SIZE-1];

// ===============================================================
// Clock Cycle
// ===============================================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE / 2.0) clk = ~clk;

// ===============================================================
// Main function
// ===============================================================
// for in_valid and out_valid
initial begin
	f_rotorA = $fopen("../00_TESTBED/rotor_pat/rotor_A.txt", "r");
    f_rotorB = $fopen("../00_TESTBED/rotor_pat/rotor_B.txt", "r");
    f_in     = $fopen("../00_TESTBED/string_pat/input_str.txt", "r");
    f_out    = $fopen("../00_TESTBED/string_pat/output_str.txt", "r"); 
    
	reset_task;

	for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
		input_task;
	    wait_out_valid_task;
	    check_ans_task;
	end
	PASS_task;
end
// for in_valid_2
always @(*) begin
    wait(in_valid)
    wait(~in_valid)
    // ===== Input code ===== //
    // Wait some cycles
	repeat($random() % 3 + 3) @(negedge clk);
	$display ("------------------------------------------------");
	$display ("  	           NO. %2d PATTERN            ", i_pat);
	$display ("------------------------------------------------");

    in_valid_2 = 1'b1;

    for(i = 0; i < str_size; i = i + 1) begin
        code_in = text[i];
        text_ascii[i] = ascii_out(code_in);
        @(posedge clk);     // at the same time with out_code
        code_last = code_in;
        @(negedge clk);
    end
    in_valid_2 = 1'b0;
    code_in    = 'bx;
end

// ===============================================================
// Task
// ===============================================================
task reset_task; begin 
    rst_n      = 'b1;
    in_valid   = 'b0;
	in_valid_2 = 'b0;

	crypt_mode = 'bx;
	code_in	   = 'bx;

    total_latency = 0;

    force clk = 0;

    #CYCLE;       rst_n = 0; 
    #(CYCLE * 2); rst_n = 1;
    
    if(out_valid !== 1'b0 || out_code !== 'b0) begin
        $display("----------------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      FAIL !                            ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  Output signal should be 0 after RESET  at %8t", $time);
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("----------------------------------------------------------------------------------------");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end endtask


task input_task; begin
    // ===== Initialize ===== //
    // ROTOR
    for(i = 0; i < 64; i = i + 1) begin
        a = $fscanf(f_rotorA, "%d", rotorA_table[i]);
        a = $fscanf(f_rotorB, "%d", rotorB_table[i]);
    end
    // MODE & TEXT SIZE
    a = $fscanf(f_in, "%d", crypt_mode_reg);
    a = $fscanf(f_in, "%d", str_size);
    // TEXT STRING
    for(i = 0; i < str_size; i = i + 1) begin
        a = $fscanf(f_in,  "%d", text[i]);
        a = $fscanf(f_out, "%d", golden[i]);
    end

    // ===== Random delay for 2 ~ 5 cycle ===== //
    repeat($random() % 3 + 2) @(negedge clk);

	// ===== Input rotor ===== //
	in_valid = 1'b1;
    
	// for load rotor A
    for(i = 0; i < 64; i = i + 1) begin
        code_in = rotorA_table[i];
		
		if(i == 0) 	crypt_mode = crypt_mode_reg;
		else		crypt_mode = 'bx;
        
		@(negedge clk);
    end

	// for load rotor B
    for(i = 0; i < 64; i = i + 1) begin
        code_in = rotorB_table[i];
        @(negedge clk);
    end
    in_valid = 1'b0;
    code_in  = 'bx;
end endtask 



task wait_out_valid_task; begin
    latency = -1;
    wait(in_valid_2);
    while(out_valid !== 1'b1) begin
        latency = latency + 1;
    	if(latency == CYCLE_DELAY) begin
            $display("--------------------------------------------------------------------------------");
            $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
            $display("    ▄▀            ▀▄      ▄▄                                          ");
            $display("    █  ▀   ▀       ▀▄▄   █  █      FAIL !                            ");
            $display("    █   ▀▀            ▀▀▀   ▀▄  ╭   The execution cycles are over %3d\033[m", CYCLE_DELAY);
            $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
            $display("    ▀▄                       █                                           ");
            $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
            $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
            $display("--------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
    	end
    	@(negedge clk);
   	end
    if(latency === 0) latency = 1;
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    out_idx     = 0;
    total_error = 0;
    while(out_valid === 1) begin
        if (out_code !== golden[out_idx]) begin
			$display("\033[0;32;31m--------------------------------------------------------\033[m");
            $display("\033[0;32;31m		          FAIL  at code %0d                        \033[m", out_idx);
            $display("\033[0;32;31m   [Code %0d] Code_in = %h, out_code = %h, Golden = %h  \033[m", out_idx, code_last, out_code, golden[out_idx]);
			$display("\033[0;32;31m--------------------------------------------------------\033[m");
            total_error = total_error + 1;
            repeat(2)@(negedge clk);
            $finish;
        end
        golden_ascii[out_idx] = ascii_out(out_code);
        @(negedge clk);
        out_idx = out_idx + 1;
    end
    if(total_error === 0) begin
        $display("\033[0;32mPASS PATTERN NO.%4d, execution cycle : %3d\033[m",i_pat ,latency);
        $display("\033[0;34mOriginal Text: \033[m ");
        for(i = 0; i <str_size; i = i + 1) begin
            $write("%c", text_ascii[i]);
        end
        $display("");
        $display("\033[0;34mProcessed Text: \033[m ");
        for(i = 0; i <str_size; i = i + 1) begin
            $write("%c", golden_ascii[i]);
        end
        $display("");
    end
    repeat($random() % 2 + 2) @(negedge clk);
end endtask

task PASS_task; begin
    if(total_error === 0) begin
        $display("---------------------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      Congratulations !                            ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  You have passed all patterns ! ");
        $display("    █ ▀▄▀▄▄▀                 █  ╭  Your execution cycles = %5d cycles   ", total_latency);
        $display("    ▀▄                       █     Your clock period = %.1f ns   ", CYCLE);
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █      Total Latency = %.1f ns       ", total_latency*CYCLE);
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("---------------------------------------------------------------------------------------------");  
        repeat(2)@(negedge clk);
        $finish;
    end
    else begin
        $display("--------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      FAIL !                            ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  You have %0d errors!     ", total_error);
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("--------------------------------------------------------------------------------");  
        repeat(2)@(negedge clk);
        $finish;
    end
end endtask


// ===============================================================
// Output signal spec check
// ===============================================================
always@(*)begin
    @(negedge clk);
	if(in_valid && out_valid)begin
        $display("--------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      FAIL !                            ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  The out_valid cannot overlap with in_valid");
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("--------------------------------------------------------------------------------");  
		//repeat(9)@(negedge clk);
		$finish;			
	end	
end
always@(*)begin
    @(negedge clk);
	if(~out_valid && out_code !== 0)begin
        $display("--------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      FAIL !                            ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  The out_code should be 0 when out_valid is low");
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("--------------------------------------------------------------------------------");
		//repeat(9)@(negedge clk);
		$finish;			
	end	
end
// ===============================================================
// ASCII display function
// ===============================================================
function [8-1:0] ascii_out;
    input [6-1:0] code;
    case(code)
        6'h00: ascii_out = 8'h61; //'a'
        6'h01: ascii_out = 8'h62; //'b'
        6'h02: ascii_out = 8'h63; //'c'
        6'h03: ascii_out = 8'h64; //'d'
        6'h04: ascii_out = 8'h65; //'e'
        6'h05: ascii_out = 8'h66; //'f'
        6'h06: ascii_out = 8'h67; //'g'
        6'h07: ascii_out = 8'h68; //'h'
        6'h08: ascii_out = 8'h69; //'i'
        6'h09: ascii_out = 8'h6a; //'j'
        6'h0a: ascii_out = 8'h6b; //'k'
        6'h0b: ascii_out = 8'h6c; //'l'
        6'h0c: ascii_out = 8'h6d; //'m'
        6'h0d: ascii_out = 8'h6e; //'n'
        6'h0e: ascii_out = 8'h6f; //'o'
        6'h0f: ascii_out = 8'h70; //'p'
        6'h10: ascii_out = 8'h71; //'q'
        6'h11: ascii_out = 8'h72; //'r'
        6'h12: ascii_out = 8'h73; //'s'
        6'h13: ascii_out = 8'h74; //'t'
        6'h14: ascii_out = 8'h75; //'u'
        6'h15: ascii_out = 8'h76; //'v'
        6'h16: ascii_out = 8'h77; //'w'
        6'h17: ascii_out = 8'h78; //'x'
        6'h18: ascii_out = 8'h79; //'y'
        6'h19: ascii_out = 8'h7a; //'z'
        6'h1a: ascii_out = 8'h20; //' '
        6'h1b: ascii_out = 8'h3f; //'?'
        6'h1c: ascii_out = 8'h2c; //','
        6'h1d: ascii_out = 8'h2d; //'-'
        6'h1e: ascii_out = 8'h2e; //'.'
        6'h1f: ascii_out = 8'h0a; //'\n' (change line)
        6'h20: ascii_out = 8'h41; //'A'
        6'h21: ascii_out = 8'h42; //'B'
        6'h22: ascii_out = 8'h43; //'C'
        6'h23: ascii_out = 8'h44; //'D'
        6'h24: ascii_out = 8'h45; //'E'
        6'h25: ascii_out = 8'h46; //'F'
        6'h26: ascii_out = 8'h47; //'G'
        6'h27: ascii_out = 8'h48; //'H'
        6'h28: ascii_out = 8'h49; //'I'
        6'h29: ascii_out = 8'h4a; //'J'
        6'h2a: ascii_out = 8'h4b; //'K'
        6'h2b: ascii_out = 8'h4c; //'L'
        6'h2c: ascii_out = 8'h4d; //'M'
        6'h2d: ascii_out = 8'h4e; //'N'
        6'h2e: ascii_out = 8'h4f; //'O'
        6'h2f: ascii_out = 8'h50; //'P'
        6'h30: ascii_out = 8'h51; //'Q'
        6'h31: ascii_out = 8'h52; //'R'
        6'h32: ascii_out = 8'h53; //'S'
        6'h33: ascii_out = 8'h54; //'T'
        6'h34: ascii_out = 8'h55; //'U'
        6'h35: ascii_out = 8'h56; //'V'
        6'h36: ascii_out = 8'h57; //'W'
        6'h37: ascii_out = 8'h58; //'X'
        6'h38: ascii_out = 8'h59; //'Y'
        6'h39: ascii_out = 8'h5a; //'Z'
        6'h3a: ascii_out = 8'h3a; //':'
        6'h3b: ascii_out = 8'h23; //'#'
        6'h3c: ascii_out = 8'h3b; //';'
        6'h3d: ascii_out = 8'h5f; //'_'
        6'h3e: ascii_out = 8'h2b; //'+'
        6'h3f: ascii_out = 8'h26; //'&'
    endcase
endfunction

endmodule
