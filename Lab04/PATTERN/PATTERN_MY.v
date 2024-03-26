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

//https://www.rapidtables.com/convert/number/binary-to-hex.html
//https://baseconvert.com/ieee-754-floating-point
`define CYCLE_TIME      27.0
`define SEED_NUMBER     28825252
`ifdef RTL
    `define PATTERN_NUMBER 10000
`endif
`ifdef GATE
    `define PATTERN_NUMBER 1000
`endif


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
output  reg        clk, rst_n, in_valid;
output  reg [31:0]  Img;
output  reg [31:0]  Kernel;
output  reg [31:0]  Weight;
output  reg [ 1:0]  Opt;
input           out_valid;
input   [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_extra_prec = 0;
parameter FP_small = 32'h38D1B717;  //0.0001

genvar i_input,i_row;
genvar i_pic,i_round,idx,idy;
integer i_pat , i , j ,k, round ;
integer out_counter;
integer latency,total_latency;
real CYCLE = `CYCLE_TIME;
real PATNUM = `PATTERN_NUMBER;
real seed = `SEED_NUMBER;
wire [31:0] _errAllow = 32'h3B03126F;// ERROR CHECK 0.002
wire _isErr;
wire _toosmall;
//---------------------------------------------------------------------
//   Reg  DECLARATION
//---------------------------------------------------------------------
reg [1:0] Opt_in;
//Img
reg [31:0] Img_in [0:47];
//Kernel
reg [31:0] Kernel_in[0:26];
reg [31:0] kernel[0:2][0:2][0:2];
//Weight
reg [31:0] Weight_in[0:3];
//padding
reg [31:0] Img_1_1[0:5][0:5];
reg [31:0] Img_1_2[0:5][0:5];
reg [31:0] Img_1_3[0:5][0:5];
reg [31:0] img[0:2][0:5][0:5];
//conv_out
reg [31:0] conv[0:2][0:3][0:3];
reg [31:0] conv_img[0:3][0:3];  //three conv picture add
reg [31:0] mult_temp[0:2][0:3][0:3][0:8];
reg [31:0] add_temp[0:2][0:3][0:3][0:8];
//max_pooling
reg [31:0] mp[0:1][0:1];
reg [31:0] max_temp1[0:1][0:1],max_temp2[0:1][0:1];
//fully_connected
reg [31:0] fc[0:3];
reg [31:0] mult_temp_fc1[0:1][0:1],mult_temp_fc2[0:1][0:1]; //mult_out
reg [31:0] fc_sum;
//normalize
reg [31:0] norm[0:3];  //flatten
//encode
wire [31:0] _encode_w[0:3];

//耍白癡
integer color_stage = 0, color, r = 5, g = 0, b = 0;
//---------------------------------------------------------------------
//  task
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE/2) clk = ~clk;

initial begin
    total_latency = 0;
    reset_task;
    @(negedge clk);
    for(i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        out_counter = 0;
        //cal_golden_task;
        wait_out_valid_task;
        check_ans_task;
        repeat(1) @(negedge clk);
        //$display("pass pattern No.%d, latency: %d" ,i_pat,latency );
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
        if(color < 100)
        $display("\033[38;5;%2dmPASS    PATTERN NO.%4d \033[00m | Latency:%4d    | Opt:%4d", color, i_pat+1,latency,Opt_in);
        else     
        $display("\033[38;5;%2dmPASS    PATTERN NO.%4d \033[00m | Latency:%4d    | Opt:%4d", color, i_pat+1,latency,Opt_in);

    end
    repeat(100) @(negedge clk);
    PASS_task;
end


task reset_task; begin
    in_valid = 0;
    Img = 'bx;
    Kernel = 'bx;
    Weight = 'bx;
    Opt = 'bx;
    rst_n = 1;
    force clk = 0;
    #(CYCLE); rst_n = 0;
    #(CYCLE * 5); rst_n = 1;
    if(out!==0||out_valid!==0) begin
        $display("Error: Reset Task");
        $finish;
    end
    #(CYCLE); release clk;
end
endtask


task input_task;begin
    Opt_in = $random(seed)%4;
    //img 0.5~ 255 == 0 01111110(126) 00000000000000000000000 ~  0 10000110(134) 11111110000000000000000(8323072)
    for(i = 0;i<48;i=i+1)begin
        Img_in[i][31] = $random(seed)%2;
        Img_in[i][30:23] = $urandom_range(8'd134,8'd126);
        Img_in[i][22:0] = $random(seed);
        if(Img_in[i][30:23] == 134)  Img_in[i][22:0] =  $random(seed) % 8323073;  //255 = 0 10000110(134) 11111110000000000000000(8323072)
    end
    //Kernel_in  <0.5 ==   <  0 01111110(126) 00000000000000000000000
    for(i = 0;i<27;i=i+1)begin
        Kernel_in[i][31] = $random(seed)%2;
        Kernel_in[i][30:23] =$random(seed)%'d127;
        Kernel_in[i][22:0] = $random(seed);
        if(Kernel_in[i][30:23] == 126)  Kernel_in[i][22:0] = 0;
    end
    //Weight_in
    for(i = 0;i<4;i=i+1)begin
        Weight_in[i][31] = $random(seed)%2;
        Weight_in[i][30:23] =$random(seed)%'d127;
        Weight_in[i][22:0] = $random(seed);
        if(Weight_in[i][30:23] == 126)  Weight_in[i][22:0] = 0;
    end

    padding_task;

    repeat($random(seed)%2+1) @(negedge clk);
    for(i = 0;i<48;i=i+1)begin
        in_valid = 1;
        Img = Img_in[i];
        if(i==0)    Opt = Opt_in;
        else Opt = 'bx;

        if(i<27)  Kernel = Kernel_in[i];
        else Kernel = 'bx;

        if(i<4) Weight = Weight_in[i];
        else Weight = 'bx;

        @(negedge clk);
    end
    in_valid = 0;
    Img = 'bx;
    Kernel = 'bx;
    Weight = 'bx;
    Opt = 'bx;
end endtask

task wait_out_valid_task;begin
    latency = -1;
    while(out_valid !== 1)begin
        if(out !== 0) begin
            $display("ERROR!Out is not 0 when out_valid is not 1");
            $finish;
        end
        if(latency == 1000)begin
            $display("ERROR!Out_valid is not 1 after 1000 cycles");
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
end endtask

reg [31:0] golden;
task check_ans_task;begin

    while(out_valid === 1 )begin
        golden = _encode_w[out_counter]; 
        if(out==='bx) begin
            $display("FAIL!out is unkown");
            $finish;
        end
        if( _isErr )begin
            if(_toosmall)begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                    WARNING!!! golden ans is smaller than 0.0001                                            ");
                $display ("                                                    Pattern NO.%03d -  %03d                                                                 ", i_pat,out_counter);
                $display ("                                                    Your output -> %b                                                                       ",out);
                $display ("                                                  Golden output -> %b                                                                       ",golden);
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			

            end
            else begin        
            $display("ERROR!out is not equal to golden_ans");
            $display("your out = %b",out);
            $display("golden_ans = %b",golden);
            $finish;
            end
        end

        out_counter = out_counter + 1;
        @(negedge clk);
    end
    if(out_counter != 4)begin
        $display("ERROR!out should remiain 4 cycles!!");
        @(negedge clk);
        $finish;
    end

end endtask

task PASS_task; begin
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
end endtask





//---------------------------------------------------------------------
//  CNN task
//---------------------------------------------------------------------
/*reg [31:0] conv_result[0:3][0:3];
reg [31:0] mp_result[0:1][0:1];
reg [31:0] fc_result[0:3];
reg [31:0] norm_result[0:3];
*/


task padding_task;begin

    for(i=0;i<3;i=i+1)
        for(j=0;j<3;j=j+1)
            for(k=0;k<3;k=k+1)
            kernel[i][j][k] = Kernel_in[i*9+j*3+k];
        

    if(~Opt_in[1])begin
    // Zero padding
        for(i=0; i<6; i=i+1) begin
            Img_1_1[i][0] = 0;
            Img_1_1[i][5] = 0;
            Img_1_2[i][0] = 0;
            Img_1_2[i][5] = 0;
            Img_1_3[i][0] = 0;
            Img_1_3[i][5] = 0;
            if(i==0 || i==5) begin
                for(j=1; j<5; j=j+1) begin
                    Img_1_1[i][j] = 0;
                    Img_1_2[i][j] = 0;
                    Img_1_3[i][j] = 0;
                end
            end
        end
     // Fill the 4x4 matrix
        for(i=1; i<5; i=i+1) begin
            for(j=1; j<5; j=j+1) begin
                Img_1_1[i][j] = Img_in[(i-1)*4 + (j-1)];
                Img_1_2[i][j] = Img_in[(i-1)*4 + (j-1) + 16];
                Img_1_3[i][j] = Img_in[(i-1)*4 + (j-1) + 32 ];
            end
        end
    end
    
    else begin
    // Replicate padding
        for(i=0; i<6; i=i+1) begin
            Img_1_1[i][0] = (i>0 && i<5) ? Img_in[(i-1)*4] : (i==0)?Img_in[0] : Img_in[12];
            Img_1_1[i][5] = (i>0 && i<5) ? Img_in[(i-1)*4 + 3] : (i==0)? Img_in[3]:Img_in[15];
            Img_1_2[i][0] = (i>0 && i<5) ? Img_in[(i-1)*4 + 16] : (i==0)?Img_in[0 + 16] : Img_in[12 + 16];
            Img_1_2[i][5] = (i>0 && i<5) ? Img_in[(i-1)*4 + 3 + 16] : (i==0)? Img_in[3 + 16]:Img_in[15 + 16];
            Img_1_3[i][0] = (i>0 && i<5) ? Img_in[(i-1)*4 + 32] : (i==0)?Img_in[0 + 32] : Img_in[12 + 32];
            Img_1_3[i][5] = (i>0 && i<5) ? Img_in[(i-1)*4 + 3 + 32] : (i==0)? Img_in[3 + 32]:Img_in[15 + 32];

            if(i==0) begin
                for(j=1; j<5; j=j+1) begin
                    Img_1_1[i][j] = Img_in[j-1];
                    Img_1_2[i][j] = Img_in[j-1 + 16];
                    Img_1_3[i][j] = Img_in[j-1 + 32];
                end
            end
            if(i==5) begin
                for(j=1; j<5; j=j+1) begin
                    Img_1_1[i][j] = Img_in[12 + j-1];
                    Img_1_2[i][j] = Img_in[12 + j-1 + 16];
                    Img_1_3[i][j] = Img_in[12 + j-1 + 32];
                end
            end
        end

    // Fill the 4x4 matrix
        for(i=1; i<5; i=i+1) begin
            for(j=1; j<5; j=j+1) begin
                Img_1_1[i][j] = Img_in[(i-1)*4 + (j-1)];
                Img_1_2[i][j] = Img_in[(i-1)*4 + (j-1) + 16];
                Img_1_3[i][j] = Img_in[(i-1)*4 + (j-1) + 32 ];
            end
        end    
    end
    //fill img
        for(i=0;i<6;i=i+1)
            for(j=0;j<6;j=j+1)
                img[0][i][j] = Img_1_1[i][j];
        for(i=0;i<6;i=i+1)
            for(j=0;j<6;j=j+1)
                img[1][i][j] = Img_1_2[i][j];
        for(i=0;i<6;i=i+1)
            for(j=0;j<6;j=j+1)
                img[2][i][j] = Img_1_3[i][j];
end endtask
//=================
// Convolution
//=================
generate
        for(i_round = 0;i_round<3;i_round = i_round+1) begin
            for(idx=0;idx<4;idx=idx+1) begin
                for(idy=0;idy<4;idy=idy+1)begin

                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U1_mult( .a(img[i_round][0+idx][0+idy]), .b(kernel[i_round][0][0]), .rnd(3'b0), .z(mult_temp[i_round][idx][idy][0]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U2_mult( .a(img[i_round][0+idx][1+idy]), .b(kernel[i_round][0][1]), .rnd(3'b0), .z(mult_temp[i_round][idx][idy][1]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U3_mult ( .a(img[i_round][0+idx][2+idy]), .b(kernel[i_round][0][2]), .rnd(3'b0), .z(mult_temp[i_round][idx][idy][2]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U4_mult ( .a(img[i_round][1+idx][0+idy]), .b(kernel[i_round][1][0]), .rnd(3'b0), .z(mult_temp[i_round][idx][idy][3]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U5_mult ( .a(img[i_round][1+idx][1+idy]), .b(kernel[i_round][1][1]), .rnd(3'b0), .z(mult_temp [i_round][idx][idy][4]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U6_mult ( .a(img[i_round][1+idx][2+idy]), .b(kernel[i_round][1][2]), .rnd(3'b0), .z(mult_temp [i_round][idx][idy][5]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U7_mult ( .a(img[i_round][2+idx][0+idy]), .b(kernel[i_round][2][0]), .rnd(3'b0), .z(mult_temp [i_round][idx][idy][6]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U8_mult ( .a(img[i_round][2+idx][1+idy]), .b(kernel[i_round][2][1]), .rnd(3'b0), .z(mult_temp [i_round][idx][idy][7]), .status( ) );
                DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                U9_mult ( .a(img[i_round][2+idx][2+idy]), .b(kernel[i_round][2][2]), .rnd(3'b0), .z(mult_temp [i_round][idx][idy][8]), .status( ) );

                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u2 ( .a(mult_temp [i_round][idx][idy][0]), .b(mult_temp [i_round][idx][idy][1]), .rnd(3'b0),.op(1'b0), .z(add_temp [i_round][idx][idy][1]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u3 ( .a(add_temp [i_round][idx][idy][1]), .b(mult_temp [i_round][idx][idy][2]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][2]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u4 ( .a(add_temp [i_round][idx][idy][2]), .b(mult_temp [i_round][idx][idy][3]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][3]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u5 ( .a(add_temp [i_round][idx][idy][3]), .b(mult_temp [i_round][idx][idy][4]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][4]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u6 ( .a(add_temp [i_round][idx][idy][4]), .b(mult_temp [i_round][idx][idy][5]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][5]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u7 ( .a(add_temp [i_round][idx][idy][5]), .b(mult_temp [i_round][idx][idy][6]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][6]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u8 ( .a(add_temp [i_round][idx][idy][6]), .b(mult_temp [i_round][idx][idy][7]), .rnd(3'b0), .op(1'b0), .z(add_temp [i_round][idx][idy][7]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u9 ( .a(add_temp [i_round][idx][idy][7]), .b(mult_temp [i_round][idx][idy][8]), .rnd(3'b0), .op(1'b0), .z(conv [i_round][idx][idy]), .status() );
                end
            end
        end

endgenerate
//conv_sum
wire [31:0] conv_add[0:3][0:3];
genvar conv_i,conv_j,conv_k;
generate

        for(conv_i = 0;conv_i<4;conv_i = conv_i+1) begin
            for(conv_j=0;conv_j<4;conv_j=conv_j+1)begin
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u100 ( .a(conv [0][conv_i][conv_j]), .b(conv [1][conv_i][conv_j]), .rnd(3'b0), .op(1'b0), .z(conv_add [conv_i][conv_j]), .status() );
                DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u200 ( .a(conv_add [conv_i][conv_j]), .b(conv [2][conv_i][conv_j]), .rnd(3'b0), .op(1'b0), .z(conv_img [conv_i][conv_j]), .status() );
            end
        end

    
endgenerate



//=================
// Max pooling
//=================
generate
        for(idx=0;idx<2;idx=idx+1)begin
            for(idy=0;idy<2;idy=idy+1)begin
                DW_fp_cmp  #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u_C1 ( .a(conv_img[idx*2][idy*2]), .b(conv_img[idx*2][idy*2+1]), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), 
                .z0(), .z1(max_temp1[idx][idy]), .status0(), .status1() );
                DW_fp_cmp  #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u_C2 ( .a(conv_img[idx*2+1][idy*2]), .b(conv_img[idx*2+1][idy*2+1]), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), 
                .z0(), .z1(max_temp2[idx][idy]), .status0(), .status1() );
                DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                u_C3 ( .a(max_temp1[idx][idy]), .b(max_temp2[idx][idy]), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), 
                .z0(), .z1(mp[idx][idy]), .status0(), .status1() );
            end
        end
endgenerate
//=================
// Fully connected
//=================
generate

        for(idx=0;idx<2;idx=idx+1) begin
            for(idy=0;idy<2;idy=idy+1)begin
                    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    U10_mult ( .a(mp[idx][0]), .b(Weight_in[idy]), .rnd(3'b0), .z(mult_temp_fc1[idx][idy]), .status( ) );
                    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    U11_mult ( .a(mp[idx][1]), .b(Weight_in[2+idy]), .rnd(3'b0), .z(mult_temp_fc2[idx][idy]), .status( ) );
                    DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    A10_add ( .a(mult_temp_fc1[idx][idy]), .b(mult_temp_fc2[idx][idy]), .rnd(3'b0), .op(1'b0), .z(fc[idx*2 + idy]), .status() );
            end
        end

endgenerate


//=================
// Normalization
//=================
generate
        for(idx=0 ; idx<4 ; idx=idx+1) begin
            wire [inst_sig_width+inst_exp_width:0] min;
            wire [inst_sig_width+inst_exp_width:0] max;
            wire [inst_sig_width+inst_exp_width:0] num_diff;
            wire [inst_sig_width+inst_exp_width:0] deno_diff;
            wire [inst_sig_width+inst_exp_width:0] div_out;
            wire [7:0] status_inst;
            findMinAndMax#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                FMAM(
                    fc[0],
                    fc[1],
                    fc[2],
                    fc[3],
                    min, max
                );
            DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                S0 (.a(fc[idx]), .b(min), .op(1'd1), .rnd(3'd0), .z(num_diff));
            DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                S1 (.a(max), .b(min), .op(1'd1), .rnd(3'd0), .z(deno_diff));
            DW_fp_div#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                D0 (.a(num_diff), .b(deno_diff), .rnd(3'd0), .z(norm[idx]), .status(status_inst));
        end
endgenerate
//=================
// Encode
//=================
generate
        for(i_row=0 ; i_row<4 ; i_row=i_row+1) begin
            wire [inst_sig_width+inst_exp_width:0] sigmoid_out;
            wire [inst_sig_width+inst_exp_width:0] tanh_out;
            wire [inst_sig_width+inst_exp_width:0] ReLU_out;
            wire [inst_sig_width+inst_exp_width:0] softplus_out;
            sigmoid#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                s(norm[i_row], sigmoid_out);
            tanh#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                t(norm[i_row], tanh_out);
            ReLU#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                r(norm[i_row], ReLU_out);
            softplus#(inst_sig_width, inst_exp_width,  inst_extra_prec,inst_ieee_compliance)
                u_S (norm[i_row], softplus_out);

            assign _encode_w[i_row] = Opt_in==0 ? ReLU_out : Opt_in==1? tanh_out : Opt_in==2? sigmoid_out : softplus_out;
        end

endgenerate




//======================================
//      Error Calculation
//======================================
// gold - ans
generate
        wire [inst_sig_width+inst_exp_width:0] golden_ans;
        wire [inst_sig_width+inst_exp_width:0] bound;
        wire [inst_sig_width+inst_exp_width:0] error_diff;
        wire [inst_sig_width+inst_exp_width:0] error_diff_pos;

        assign golden_ans = _encode_w[out_counter]; 

        // FP_SMALL < |golden|  toosmall=1
        DW_fp_cmp
        #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  
            Err_C1 (.a(FP_small), .b({1'b0,golden_ans[30:0]}), .agtb(_toosmall), .zctr(1'd0));

        DW_fp_sub
        #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
            Err_S0 (.a(golden_ans), .b(out), .z(error_diff), .rnd(3'd0));

        // gold * _errAllow
        DW_fp_mult
        #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
            Err_M0 (.a(_errAllow), .b(golden_ans), .z(bound), .rnd(3'd0));

        // check |gold - ans| > _errAllow * gold
        DW_fp_cmp
        #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
            Err_C2 (.a(error_diff_pos), .b(bound), .agtb(_isErr), .zctr(1'd0));

        assign error_diff_pos = error_diff[inst_sig_width+inst_exp_width] ? {1'b0, error_diff[inst_sig_width+inst_exp_width-1:0]} : error_diff;


endgenerate
endmodule




module findMinAndMax
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1
)
(
    input  [inst_sig_width+inst_exp_width:0] a0, a1, a2, a3,
    output [inst_sig_width+inst_exp_width:0] minOut, maxOut
);
    wire [inst_sig_width+inst_exp_width:0] max0;
    wire [inst_sig_width+inst_exp_width:0] max1;
    wire [inst_sig_width+inst_exp_width:0] min0;
    wire [inst_sig_width+inst_exp_width:0] min1;
    wire flag0;
    wire flag1;
    wire flag2;
    wire flag3;
    DW_fp_cmp
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
        C0_1 (.a(a0), .b(a1), .agtb(flag0), .zctr(1'd0));
    DW_fp_cmp
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
        C1_2 (.a(a2), .b(a3), .agtb(flag1), .zctr(1'd0));
    
    DW_fp_cmp
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
        Cmax (.a(max0), .b(max1), .agtb(flag2), .zctr(1'd0));
    DW_fp_cmp
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
        Cmin (.a(min0), .b(min1), .agtb(flag3), .zctr(1'd0));

    assign max0 = flag0==1 ? a0 : a1;
    assign max1 = flag1==1 ? a2 : a3;

    assign min0 = flag0==1 ? a1 : a0;
    assign min1 = flag1==1 ? a3 : a2;
    assign maxOut = flag2==1 ? max0 : max1;
    assign minOut = flag3==1 ? min1 : min0;
endmodule

module sigmoid
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 0,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_gain1 = 32'h3F800000; // Activation 1.0
    wire [inst_sig_width+inst_exp_width:0] float_gain2 = 32'hBF800000; // Activation -1.0
    wire [inst_sig_width+inst_exp_width:0] x_neg;
    wire [inst_sig_width+inst_exp_width:0] exp;
    wire [inst_sig_width+inst_exp_width:0] deno;

    DW_fp_mult // -x
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        M0 (.a(in), .b(float_gain2), .rnd(3'd0), .z(x_neg));
    
    DW_fp_exp // exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E0 (.a(x_neg), .z(exp));
    
    DW_fp_addsub // 1+exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(float_gain1), .b(exp), .op(1'd0), .rnd(3'd0), .z(deno));
    
    DW_fp_div // 1 / [1+exp(-x)]
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
        D0 (.a(float_gain1), .b(deno), .rnd(3'd0), .z(out));
endmodule

module tanh
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_gain1 = 32'h3F800000; // Activation 1.0
    wire [inst_sig_width+inst_exp_width:0] float_gain2 = 32'hBF800000; // Activation -1.0
    wire [inst_sig_width+inst_exp_width:0] x_neg;
    wire [inst_sig_width+inst_exp_width:0] exp_pos;
    wire [inst_sig_width+inst_exp_width:0] exp_neg;
    wire [inst_sig_width+inst_exp_width:0] nume;
    wire [inst_sig_width+inst_exp_width:0] deno;

    DW_fp_mult // -x
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        M0 (.a(in), .b(float_gain2), .rnd(3'd0), .z(x_neg));
    
    DW_fp_exp // exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E0 (.a(x_neg), .z(exp_neg));

    DW_fp_exp // exp(x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E1 (.a(in), .z(exp_pos));

    //

    DW_fp_addsub // exp(x)-exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(exp_pos), .b(exp_neg), .op(1'd1), .rnd(3'd0), .z(nume));

    DW_fp_addsub // exp(x)+exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A1 (.a(exp_pos), .b(exp_neg), .op(1'd0), .rnd(3'd0), .z(deno));

    DW_fp_div // [exp(x)-exp(-x)] / [exp(x)+exp(-x)]
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
        D0 (.a(nume), .b(deno), .rnd(3'd0), .z(out));
endmodule

module ReLU
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    // x < 0 ? 0 : x
    assign out = in[inst_sig_width+inst_exp_width] ? 32'd0 : in;
endmodule

module softplus
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1,
    parameter inst_extra_prec      = 0,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_gain1 = 32'h3F800000; // Activation 1.0
    wire [inst_sig_width+inst_exp_width:0] exp;
    wire [inst_sig_width+inst_exp_width:0] exp_1;



    DW_fp_exp // exp(x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E0 (.a(in), .z(exp));


    DW_fp_addsub // exp(x) + 1
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(exp), .b(float_gain1), .op(1'd0), .rnd(3'd0), .z(exp_1));
    //ln(exp(x)+1)
    DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_extra_prec,inst_arch)
        U1 (.a(exp_1),.z(out),.status() );
endmodule