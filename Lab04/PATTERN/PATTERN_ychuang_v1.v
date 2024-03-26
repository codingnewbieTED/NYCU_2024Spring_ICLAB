//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME  26.0
`define PAT_NUM     1000
`define EXP_MIN     117
`define EXP_MAX     137

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,
    //Input Port
    out_valid,
    out
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg        clk, rst_n, in_valid;
output reg [31:0] Img;
output reg [31:0] Kernel;
output reg [31:0] Weight;
output reg [ 1:0] Opt;
input             out_valid;
input      [31:0] out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

localparam [31:0] FP_ONE     = 32'h3f800000;  // 1.0
localparam [31:0] FP_INVALID = 32'h38d1b717;  // 1e-4
localparam [31:0] FP_ERROR   = 32'h3b03126f;  // 0.002

///////////////////////////////////////////////////////////////////////

reg  [31:0] add_a;
reg  [31:0] add_b;
wire [31:0] add_z;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DW_fp_add_0 (
    .a(add_a),
    .b(add_b),
    .rnd(3'b000),
    .z(add_z),
    .status()
);

reg  [31:0] sub_a;
reg  [31:0] sub_b;
wire [31:0] sub_z;

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DW_fp_sub_0 (
    .a(sub_a),
    .b(sub_b),
    .rnd(3'b000),
    .z(sub_z),
    .status()
);

reg  [31:0] mul_a;
reg  [31:0] mul_b;
wire [31:0] mul_z;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DW_fp_mult_0 (
    .a(mul_a),
    .b(mul_b),
    .rnd(3'b000),
    .z(mul_z),
    .status()
);

reg  [31:0] div_a;
reg  [31:0] div_b;
wire [31:0] div_z;

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) DW_fp_div_0 (
    .a(div_a),
    .b(div_b),
    .rnd(3'b000),
    .z(div_z),
    .status()
);

reg  [31:0] exp_a;
wire [31:0] exp_z;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) DW_fp_exp_0 (
    .a(exp_a),
    .z(exp_z),
    .status()
);

reg  [31:0] ln_a;
wire [31:0] ln_z;

DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0, inst_arch) DW_fp_ln_0 (
    .a(ln_a),
    .z(ln_z),
    .status()
);

reg  [31:0] cmp_a;
reg  [31:0] cmp_b;
wire        cmp_agtb;
wire [31:0] cmp_z0;
wire [31:0] cmp_z1;

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DW_fp_cmp_0 (
    .a(cmp_a),
    .b(cmp_b),
    .zctr(1'b0),
    .aeqb(),
    .altb(),
    .agtb(cmp_agtb),
    .unordered(),
    .z0(cmp_z0),
    .z1(cmp_z1),
    .status0(),
    .status1()
);

///////////////////////////////////////////////////////////////////////

real cycle = `CYCLE_TIME;

integer i, j, k, l, m;
integer i_pat;
integer i_input;
integer i_result;

reg [31:0] I_in [0:47];
reg [31:0] K_in [0:26];
reg [31:0] W_in [0:3];
reg [ 1:0] opt_r;

reg [31:0] I [0:2][0:3][0:3];
reg [31:0] K [0:2][0:2][0:2];
reg [31:0] W [0:1][0:1];
reg [31:0] P [0:2][0:5][0:5];
reg [31:0] F [0:3][0:3];
reg [31:0] A [0:1][0:1];
reg [31:0] L [0:3];
reg [31:0] L_min;
reg [31:0] L_range;
reg [31:0] R [0:3];
reg [31:0] U [0:3];

reg [31:0] tmp [0:3];
reg        ans_excluded;

integer latency;
integer total_latency;

reg [31:0] result [0:3];
reg [31:0] diff   [0:3];

///////////////////////////////////////////////////////////////////////

initial clk = 0;
always #(cycle/2.0) clk = ~clk;

initial begin
    reset_signal_task;

    total_latency = 0;
    for (i_pat = 1; i_pat <= `PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("PASS PATTERN %6d, LATENCY %4d, DIFF %e %e %e %e", i_pat, latency, 
                                                                    $bitstoshortreal(diff[0]),
                                                                    $bitstoshortreal(diff[1]),
                                                                    $bitstoshortreal(diff[2]),
                                                                    $bitstoshortreal(diff[3]));
        total_latency = total_latency + latency;
    end

    pass_task;
end

always @(negedge clk) begin
    if (out_valid === 1'b0 && out !== 0)
        $fatal("FAIL: OUT SHOULD BE RESET WHEN OUT_VALID IS DEASSERTED");
end

always @(posedge clk) begin
    if (in_valid === 1'b1 && out_valid === 1'b1)
        $fatal("FAIL: IN_VALID CANNOT OVERLAP OUT_VALID");
end

//////////////////////////////////////////////////////////////////////

task reset_signal_task; 
begin 
    force clk = 1'b0;
    rst_n     = 1'b1;
    in_valid  = 1'b0;
    Img       = {32{1'bx}};
    Kernel    = {32{1'bx}};
    Weight    = {32{1'bx}};
    Opt       = {32{1'bx}};
    #(100);
    rst_n = 1'b0;
    #(100);
    if (out_valid !== 0 || out !== 0)
        $fatal("FAIL: RESET");
    #(100);
    rst_n = 1'b1;
    #(100);
    release clk;
    #(100);
end 
endtask

task input_task; 
begin 
    repeat ($urandom_range(0, 5)) 
        @(negedge clk);
    
    forever begin
        l = 0;
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                for (k = 0; k < 4; k = k + 1) begin
                    I_in[l][31]    = $urandom;
                    I_in[l][30:23] = $urandom_range(`EXP_MIN, `EXP_MAX);
                    I_in[l][22:0]  = $urandom;
                    I[i][j][k] = I_in[l];
                    l = l + 1;
                end
            end
        end

        l = 0;
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                for (k = 0; k < 3; k = k + 1) begin
                    K_in[l][31]    = $urandom;
                    K_in[l][30:23] = $urandom_range(`EXP_MIN, `EXP_MAX);
                    K_in[l][22:0]  = $urandom;
                    K[i][j][k] = K_in[l];
                    l = l + 1;
                end
            end
        end

        l = 0;
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 2; j = j + 1) begin
                W_in[l][31]    = $urandom;
                W_in[l][30:23] = $urandom_range(`EXP_MIN, `EXP_MAX);
                W_in[l][22:0]  = $urandom;
                W[i][j] = W_in[l];
                l = l + 1;
            end
        end

        opt_r = $urandom;

        calc_ans_task;
        ans_excluded = 0;
        for (i = 0; i < 4; i = i + 1) begin
            cmp_a = {1'b0, U[i][30:0]};
            cmp_b = FP_INVALID;
            #0;
            if (U[i] != 0 && ~cmp_agtb)
                ans_excluded = 1;
        end

        if (~ans_excluded)
            break;
    end

    in_valid = 1'b1;
    for (i_input = 0; i_input < 48; i_input = i_input + 1) begin
        Img    = I_in[i_input];
        Kernel = i_input < 27 ? K_in[i_input] : {32{1'bx}};
        Weight = i_input < 4  ? W_in[i_input] : {32{1'bx}};
        Opt    = i_input < 1  ? opt_r : 2'bxx;
        @(negedge clk);
    end

    in_valid = 1'b0;
    Img       = {32{1'bx}};
    @(negedge clk);
end 
endtask

task wait_out_valid_task;
begin
    latency = 0;
    while (out_valid !== 1'b1) begin
        if (latency == 1000)
            $fatal("FAIL: LATENCY");
        @(negedge clk);
        latency = latency + 1;
    end
    for (i_result = 0; i_result < 4; i_result = i_result + 1) begin
        if (out_valid !== 1'b1)
            $fatal("FAIL: OUT_VALID SHOULD ASSERT FOUR CYCLE");
        result[i_result] = out;
        @(negedge clk);
    end
    if (out_valid !== 1'b0)
        $fatal("FAIL: OUT_VALID SHOULD DEASSERT AFTER FOUR CYCLE");
end
endtask

task check_ans_task;
begin
    for (i = 0; i < 4; i = i + 1) begin
        diff[i] = 0;
        for (j = 0; j < 32; j = j + 1)
            if (result[i][j] === 1'bx)
                $fatal("FAIL: RESULT CONTAINS X");
        if (U[i] !== result[i]) begin
            sub_a = U[i];
            sub_b = result[i];
            #0;
            div_a = sub_z;
            div_b = U[i];
            #0;
            diff[i] = {1'b0, div_z[30:0]};

            cmp_a = FP_ERROR;
            cmp_b = diff[i];
            #0;
            if (~cmp_agtb)
                $fatal("FAIL: RESULT NOT MATCH");
        end
    end
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
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 6; j = j + 1) begin
            for (k = 0; k < 6; k = k + 1) begin
                l = (j == 0 ? 0 : j == 5 ? 3 : j - 1);
                m = (k == 0 ? 0 : k == 5 ? 3 : k - 1);
                if ((opt_r == 2'd0 || opt_r == 2'd1) && (j == 0 || j == 5 || k == 0 || k == 5))
                    P[i][j][k] = 0;
                else
                    P[i][j][k] = I[i][l][m];
            end
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            F[i][j] = 0;
            for (k = 0; k < 3; k = k + 1) begin
                for (l = 0; l < 3; l = l + 1) begin
                    for (m = 0; m < 3; m = m + 1) begin
                        mul_a = P[k][i+l][j+m];
                        mul_b = K[k][l][m];
                        #0;
                        add_a = F[i][j];
                        add_b = mul_z;
                        #0;
                        F[i][j] = add_z;
                    end
                end
            end
        end
    end

    for (i = 0; i < 2; i = i + 1) begin
        for (j = 0; j < 2; j = j + 1) begin
            cmp_a = F[i*2][j*2];
            cmp_b = F[i*2][j*2+1];
            #0;
            cmp_a = cmp_z1;
            cmp_b = F[i*2+1][j*2];
            #0;
            cmp_a = cmp_z1;
            cmp_b = F[i*2+1][j*2+1];
            #0;
            A[i][j] = cmp_z1;
        end
    end

    for (i = 0; i < 2; i = i + 1) begin
        for (j = 0; j < 2; j = j + 1) begin
            L[i*2+j] = 0;
            for (k = 0; k < 2; k = k + 1) begin
                mul_a = A[i][k];
                mul_b = W[k][j];
                #0;
                add_a = L[i*2+j];
                add_b = mul_z;
                #0;
                L[i*2+j] = add_z;
            end
        end
    end

    cmp_a = L[0];
    cmp_b = L[1];
    #0;
    cmp_a = cmp_z0;
    cmp_b = L[2];
    #0;
    cmp_a = cmp_z0;
    cmp_b = L[3];
    #0;
    L_min = cmp_z0;

    cmp_a = L[0];
    cmp_b = L[1];
    #0;
    cmp_a = cmp_z1;
    cmp_b = L[2];
    #0;
    cmp_a = cmp_z1;
    cmp_b = L[3];
    #0;
    sub_a = cmp_z1;
    sub_b = L_min;
    #0;
    L_range = sub_z;

    for (i = 0; i < 4; i = i + 1) begin
        sub_a = L[i];
        sub_b = L_min;
        #0;
        div_a = sub_z;
        div_b = L_range;
        #0;
        R[i] = div_z;
    end

    for (i = 0; i < 4; i = i + 1) begin
        case (opt_r)
            2'd0: begin
                cmp_a = 0;
                cmp_b = R[i];
                #0;
                U[i] = cmp_z1;
            end
            2'd1: begin
                exp_a = R[i];
                #0;
                tmp[0] = exp_z;

                exp_a = {~R[i][31], R[i][30:0]};
                #0;
                tmp[1] = exp_z;

                sub_a = tmp[0];
                sub_b = tmp[1];
                #0;
                tmp[2] = sub_z;

                add_a = tmp[0];
                add_b = tmp[1];
                #0;
                tmp[3] = add_z;
                
                div_a = tmp[2];
                div_b = tmp[3];
                #0;
                U[i] = div_z;
            end
            2'd2: begin
                exp_a = {~R[i][31], R[i][30:0]};
                #0;
                add_a = FP_ONE;
                add_b = exp_z;
                #0;
                div_a = FP_ONE;
                div_b = add_z;
                #0;
                U[i] = div_z;
            end
            2'd3: begin
                exp_a = R[i];
                #0;
                add_a = FP_ONE;
                add_b = exp_z;
                #0;
                ln_a = add_z;
                #0;
                U[i] = ln_z;
            end
        endcase
    end
end
endtask

endmodule
