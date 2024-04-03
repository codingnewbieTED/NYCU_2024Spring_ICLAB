`define CYCLE_TIME  20.0
`define PAT_NUM     1000

module PATTERN(
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    mode,
    matrix,
    matrix_size,
    matrix_idx,
    out_valid,
    out_value
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg       clk;
output reg       rst_n;
output reg       in_valid;
output reg       in_valid2;
output reg [1:0] matrix_size;
output reg [7:0] matrix;
output reg [3:0] matrix_idx;
output reg       mode;

input out_valid;
input out_value;

///////////////////////////////////////////////////////////////////////

real cycle = `CYCLE_TIME;

integer i, j, k, l, m;
integer i_pat;
integer i_input2;
integer i_result, j_result, k_result, l_result;

integer latency;
integer total_latency;

integer I_size;
integer O_size;

reg [1:0] matrix_size_r;
reg [3:0] matrix_idx_r [0:1];
reg       mode_r;

reg signed [ 7:0] I [0:15][0:31][0:31];
reg signed [ 7:0] K [0:15][0: 4][0: 4];

reg signed [19:0] C [0:27][0:27];
reg signed [19:0] O [0:35][0:35];

reg signed [19:0] result [0:35][0:35];

///////////////////////////////////////////////////////////////////////

initial clk = 0;
always #(cycle/2.0) clk = ~clk;

initial begin
    reset_signal_task;

    total_latency = 0;
    for (i_pat = 1; i_pat <= `PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        for (i_input2 = 0; i_input2 < 16; i_input2 = i_input2 + 1) begin
            input2_task;
            wait_out_valid_task;
            check_ans_task;
            $display("PASS PATTERN %6d-%2d, LATENCY %4d, matrix_size %2d, mode %1d", i_pat, i_input2,
                     latency, matrix_size_r, mode_r);
        end
    end

    pass_task;
end

always @(negedge clk) begin
    if (out_valid === 1'b0 && out_value !== 0)
        $fatal(1, "FAIL: OUT SHOULD BE RESET WHEN OUT_VALID IS DEASSERTED");
end

always @(posedge clk) begin
    if (in_valid === 1'b1 && out_valid === 1'b1)
        $fatal(1, "FAIL: IN_VALID CANNOT OVERLAP OUT_VALID");
end

//////////////////////////////////////////////////////////////////////

task reset_signal_task; 
begin 
    force clk   = 1'b0;
    rst_n       = 1'b1;
    in_valid    = 1'b0;
    in_valid2   = 1'b0;
    matrix_size = {2{1'bx}};
    matrix      = {8{1'bx}};
    matrix_idx  = {4{1'bx}};
    mode        = 1'bx;
    #(100);
    rst_n = 1'b0;
    #(100);
    if (out_valid !== 0 || out_value !== 0)
        $fatal(1, "FAIL: RESET");
    #(100);
    rst_n = 1'b1;
    #(100);
    release clk;
    #(100);
end 
endtask

task input_task; 
begin 
    repeat ($urandom_range(1, 5)) 
        @(negedge clk);
    
    l = 0;
    for (i = 0; i < 16; i = i + 1)
        for (j = 0; j < 32; j = j + 1)
            for (k = 0; k < 32; k = k + 1)
                I[i][j][k] = $urandom;

    l = 0;
    for (i = 0; i < 16; i = i + 1)
        for (j = 0; j < 5; j = j + 1)
            for (k = 0; k < 5; k = k + 1)
                K[i][j][k] = $urandom;

    matrix_size_r = $urandom % 3;

    case (matrix_size_r)
        0: I_size = 8;
        1: I_size = 16;
        2: I_size = 32;
    endcase

    in_valid = 1'b1;
    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < I_size; j = j + 1) begin
            for (k = 0; k < I_size; k = k + 1) begin
                matrix_size = (i == 0 && j == 0 && k == 0) ? matrix_size_r : {2{1'bx}};
                matrix = I[i][j][k];
                @(negedge clk);
            end
        end
    end

    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            for (k = 0; k < 5; k = k + 1) begin
                matrix = K[i][j][k];
                @(negedge clk);
            end
        end
    end

    in_valid = 1'b0;
    matrix   = {8{1'bx}};
end 
endtask

task input2_task;
begin
    repeat ($urandom_range(1, 3)) 
        @(negedge clk);
    
    matrix_idx_r[0] = $urandom;
    matrix_idx_r[1] = $urandom;
    mode_r          = $urandom;
    calc_ans_task;

    in_valid2  = 1'b1;
    matrix_idx = matrix_idx_r[0];
    mode       = mode_r;
    @(negedge clk);
    matrix_idx = matrix_idx_r[1];
    mode       = 1'bx;
    @(negedge clk);

    in_valid2  = 1'b0;
    matrix_idx = {4{1'bx}};
end
endtask

task wait_out_valid_task;
begin
    latency = 0;
    while (out_valid !== 1'b1) begin
        if (latency == 100000)
            $fatal(1, "FAIL: LATENCY");
        @(negedge clk);
        latency = latency + 1;
    end
    total_latency = total_latency + latency;

    for (i_result = 0; i_result < O_size; i_result = i_result + 1) begin
        for (j_result = 0; j_result < O_size; j_result = j_result + 1) begin
            for (k_result = 0; k_result < 20; k_result = k_result + 1) begin
                if (out_valid !== 1'b1)
                    $fatal(1, "FAIL: OUT_VALID TOO SHORT");
                result[i_result][j_result][k_result] = out_value;
                @(negedge clk);
            end
        end
    end

    if (out_valid !== 1'b0)
        $fatal(1, "FAIL: OUT_VALID TOO LONG");
end
endtask

task check_ans_task;
begin
    for (i = 0; i < O_size; i = i + 1)
        for (j = 0; j < O_size; j = j + 1)
            if (result[i][j] !== O[i][j])
                $fatal(1, "FAIL: YOUR ANSWER IS INCORRECT");
end
endtask

task pass_task;
begin
    $display("Congratulations!");
    $display("Your execution cycles = %d cycles", total_latency);
    $display("Your clock period = %.1f ns", cycle);
    $display("Total Latency = %.1f ns", total_latency * cycle);
    $finish;
end 
endtask

task calc_ans_task;
begin
    for (i = 0; i < 36; i = i + 1)
        for (j = 0; j < 36; j = j + 1)
            O[i][j] = 0;

    case (mode_r)
        0: begin
            O_size = (I_size - 4) / 2;

            for (i = 0; i < I_size - 4; i = i + 1) begin
                for (j = 0; j < I_size - 4; j = j + 1) begin
                    C[i][j] = 0;
                    for (k = 0; k < 5; k = k + 1)
                        for (l = 0; l < 5; l = l + 1)
                            C[i][j] = C[i][j] + I[matrix_idx_r[0]][i+k][j+l] * K[matrix_idx_r[1]][k][l]; 
                end
            end

            for (i = 0; i < I_size - 4; i = i + 2) begin
                for (j = 0; j < I_size - 4; j = j + 2) begin
                    O[i/2][j/2] = C[i][j];
                    for (k = 0; k < 2; k = k + 1)
                        for (l = 0; l < 2; l = l + 1)
                            O[i/2][j/2] = (C[i+k][j+l] > O[i/2][j/2]) ? C[i+k][j+l] : O[i/2][j/2];
                end
            end
        end
        1: begin
            O_size = I_size + 4;

            for (i = 0; i < I_size; i = i + 1) begin
                for (j = 0; j < I_size; j = j + 1) begin
                    for (k = 0; k < 5; k = k + 1)
                        for (l = 0; l < 5; l = l + 1)
                            O[i+k][j+l] = O[i+k][j+l] + I[matrix_idx_r[0]][i][j] * K[matrix_idx_r[1]][k][l]; 
                end
            end
        end
    endcase
end
endtask

endmodule
