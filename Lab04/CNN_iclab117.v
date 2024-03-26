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
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//   1534301.803519 16,25。  
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER/integer / genvar 
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter inst_extra_prec = 0;
integer i;
//parameter
parameter FP_minus1 = 32'hBF800000;
parameter FP0 = 32'h00000000;
parameter FP1 = 32'h3F800000;
parameter FP_TANH_0 = FP0;   
parameter FP_TANH_1 = 32'h3F42F7D6;     //0.76159415595
parameter FP_SIGM_0 = 32'h3f000000;   //0.5
parameter FP_SIGM_1 = 32'h3F3B26A8;   //0.73105857863
parameter FP_SOFTP_0 = 32'h3F317218; 
parameter FP_SOFTP_1 = 32'h3FA818F6;  //3FA818F5
//================================================================
//  
//================================================================

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;
//================================================================
//   Wires & Registers 
//================================================================
wire [6:0] n_cnt;
reg  [6:0] cnt;

reg [1:0] mode;
reg [inst_sig_width + inst_exp_width:0] img [0:15];

reg [inst_sig_width + inst_exp_width:0] kernel_1 [0:8];
reg [inst_sig_width + inst_exp_width:0] kernel_2 [0:8];
wire [inst_sig_width + inst_exp_width:0] n_kernel_1 [0:8];
wire [inst_sig_width + inst_exp_width:0] n_kernel_2 [0:8];

reg [inst_sig_width + inst_exp_width:0] weight [0:3];
//padding
reg [inst_sig_width + inst_exp_width:0] img_pad [0:8];
reg [inst_sig_width + inst_exp_width:0] img_pad_3to0, img_pad_4to1, img_pad_5to2, img_pad_6to3, img_pad_7to4, img_pad_8to5;
//convolution
wire [inst_sig_width + inst_exp_width:0] conv_0, conv_1, conv_2, conv_3, conv_4, conv_5, conv_6, conv_7, conv_8;
wire [inst_sig_width + inst_exp_width:0] conv_refill;
reg [inst_sig_width + inst_exp_width:0] conv_buffer[0:6];
//maxpooling && fully conntected
reg [inst_sig_width + inst_exp_width:0] max_mp,max_mp_temp1,max_mp_temp2;
reg  [inst_sig_width + inst_exp_width:0]  in_fc_mult1 ,in_fc_mult2;
wire [inst_sig_width + inst_exp_width:0]  out_fc_mult1 ,out_fc_mult2;
reg  [inst_sig_width + inst_exp_width:0]  in_fc_add1  , in_fc_add2;   
wire [inst_sig_width + inst_exp_width:0]  out_fc_add1 , out_fc_add2;
reg  [inst_sig_width + inst_exp_width:0]  fc[0:3];
//activation
wire [inst_sig_width + inst_exp_width:0] max_n_temp1, max_n_temp2, max_n;
wire [inst_sig_width + inst_exp_width:0] min_n_temp1, min_n_temp2, min_n;
reg [inst_sig_width + inst_exp_width:0] x1, x2;
wire [3:0] order;
reg [inst_sig_width + inst_exp_width:0] norm_act_in_1, norm_act_in_2, norm_act_in_3, norm_act_in_4;
wire [inst_sig_width + inst_exp_width:0] norm_act_out1, norm_act_out2;
reg [inst_sig_width + inst_exp_width:0] norm_act_addsub_top, norm_act_addsub_bot;
wire norm_act_sub_add;
wire [inst_sig_width + inst_exp_width:0] z_2,exp_in;
reg  [inst_sig_width + inst_exp_width:0] act_exp;
wire [inst_sig_width + inst_exp_width:0] div_out;
reg [inst_sig_width + inst_exp_width:0] norm_act_div;
reg [inst_sig_width + inst_exp_width:0] div_top;
reg [inst_sig_width + inst_exp_width:0] div_bot;
 wire [inst_sig_width + inst_exp_width:0] ln_out;
wire [inst_sig_width+inst_exp_width:0] exp_out;
//output
reg [inst_sig_width + inst_exp_width:0] norm_act_div1;  //norm_act_div delay1
wire [inst_sig_width + inst_exp_width:0] activation_0, activation_1;
reg [inst_sig_width + inst_exp_width:0] n_output[0:3];
reg [1:0] cnt_out;
wire [1:0] n_cnt_out;
reg out_flag;

// ===============================================================
// Design
// ===============================================================
//counter
assign n_cnt =(&cnt_out)?0: (in_valid || |cnt )? cnt + 1 : cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt <= 0;
    else cnt <= n_cnt;
end
//img reg
always@(posedge clk) begin
    for(i=0;i<16;i=i+1)begin
        if(i==cnt[3:0])
            img[i] <= Img;
        else
            img[i] <= img[i];
    end
end
//weight reg
always@(posedge clk) begin
    if(cnt<4)begin
        weight[cnt[1:0]] <= Weight;
    end
end
//kernel reg
always@(posedge clk)begin
    for(i=0;i<9;i=i+1)begin
        kernel_1[i] <= n_kernel_1[i];
        kernel_2[i] <= n_kernel_2[i];
    end

end

assign n_kernel_1[0] = (cnt == 0)?Kernel:(cnt==16 || cnt == 32)?kernel_2[0]:kernel_1[0];
assign n_kernel_1[1] = (cnt == 1)?Kernel:(cnt==17 || cnt == 33)?kernel_2[1]:kernel_1[1];
assign n_kernel_1[2] = (cnt == 2)?Kernel:(cnt==18 || cnt == 34)?kernel_2[2]:kernel_1[2];
assign n_kernel_1[3] = (cnt == 3)?Kernel:(cnt==19 || cnt == 35)?kernel_2[3]:kernel_1[3];
assign n_kernel_1[4] = (cnt == 4)?Kernel:(cnt==20 || cnt == 36)?kernel_2[4]:kernel_1[4];
assign n_kernel_1[5] = (cnt == 5)?Kernel:(cnt==21 || cnt == 37)?kernel_2[5]:kernel_1[5];
assign n_kernel_1[6] = (cnt == 6)?Kernel:(cnt==22 || cnt == 38)?kernel_2[6]:kernel_1[6];
assign n_kernel_1[7] = (cnt == 7)?Kernel:(cnt==23 || cnt == 39)?kernel_2[7]:kernel_1[7];
assign n_kernel_1[8] = (cnt == 8)?Kernel:(cnt==24 || cnt == 40)?kernel_2[8]:kernel_1[8];

assign n_kernel_2[0] = (cnt == 9 || cnt == 18) ? Kernel : kernel_2[0];
assign n_kernel_2[1] = (cnt == 10 || cnt == 19) ? Kernel : kernel_2[1];
assign n_kernel_2[2] = (cnt == 11 || cnt == 20) ? Kernel : kernel_2[2];
assign n_kernel_2[3] = (cnt == 12 || cnt == 21) ? Kernel : kernel_2[3];
assign n_kernel_2[4] = (cnt == 13 || cnt == 22) ? Kernel : kernel_2[4];
assign n_kernel_2[5] = (cnt == 14 || cnt == 23) ? Kernel : kernel_2[5];
assign n_kernel_2[6] = (cnt == 15 || cnt == 24) ? Kernel : kernel_2[6];
assign n_kernel_2[7] = (cnt == 16 || cnt == 25) ? Kernel : kernel_2[7];
assign n_kernel_2[8] = (cnt == 17 || cnt == 26) ? Kernel : kernel_2[8];
//opt reg
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) mode <= 0;
    else if(cnt ==0 && in_valid)    mode <= Opt;
    else mode <= mode;
end
// padding

always@(*)begin
        case(cnt[3:0])
        4'd1: img_pad[0] = mode[1]? img[0]:FP0;
        4'd2: img_pad[0] = mode[1]? img[0]:FP0;
        4'd3: img_pad[0] = mode[1]? img[1]:FP0;
        4'd4: img_pad[0] = mode[1]? img[2]:FP0;
        default: img_pad[0] = img_pad_3to0;
        endcase
end

always@(*)begin
    case(cnt[3:0])
    4'd2: img_pad[1] = (mode[1])? img[0]:FP0;
    4'd3: img_pad[1] = (mode[1])? img[1]:FP0;
    4'd4: img_pad[1] = (mode[1])? img[2]:FP0;
    4'd5: img_pad[1] = (mode[1])? img[3]:FP0;
    default: img_pad[1] = img_pad_4to1;
    endcase
end

always@(*)begin
    case(cnt[3:0])
    4'd3: img_pad[2] = (mode[1])? img[1]:FP0;
    4'd4: img_pad[2] = (mode[1])? img[2]:FP0;
    4'd5: img_pad[2] = (mode[1])? img[3]:FP0;
    4'd6: img_pad[2] = (mode[1])? img[3]:FP0;
    default: img_pad[2] = img_pad_5to2;
    endcase
end

always@(*)begin
    case(cnt[3:0])
    4'd4: img_pad[3] = (mode[1])? img[0]:FP0;
    4'd5: img_pad[3] = img[0];
    4'd6: img_pad[3] = img[1];
    4'd7: img_pad[3] = img[2];
    default: img_pad[3] = img_pad_6to3;
    endcase
end

always@(*)begin
    case(cnt[3:0])
    4'd5: img_pad[4] = img[0];
    4'd6: img_pad[4] = img[1];
    4'd7: img_pad[4] = img[2];
    4'd8: img_pad[4] = img[3];
    default: img_pad[4] = img_pad_7to4;
    endcase
end

always@(*)begin
    case(cnt[3:0])
    4'd6: img_pad[5] = img[1];
    4'd7: img_pad[5] = img[2];
    4'd8: img_pad[5] = img[3];
    4'd9: img_pad[5] = (mode[1])? img[3]:FP0;
    default: img_pad[5] = img_pad_8to5;
    endcase
end

always@(*)begin   //13 14 15 16 19 20 21 22 25 26 27 28 31 32 33 34
    case(cnt[3:0])
    4'd7: img_pad[6] = (mode[1])? img[4]:FP0;
    4'd8: img_pad[6] = img[4];
    4'd9: img_pad[6] = img[5];
    4'd10:img_pad[6] = img[6];

    4'd11:img_pad[6] = (mode[1])? img[8]:FP0;
    4'd12:img_pad[6] = img[8];
    4'd13:img_pad[6] = img[9];
    4'd14:img_pad[6] = img[10];

    4'd15:img_pad[6] = (mode[1])? img[12]:FP0;
    4'd0: img_pad[6] = img[12];
    4'd1: img_pad[6] = img[13];
    4'd2: img_pad[6] = img[14];

    4'd3: img_pad[6] = (mode[1])? img[12]:FP0;
    4'd4: img_pad[6] = (mode[1])? img[12]:FP0;
    4'd5: img_pad[6] = (mode[1])? img[13]:FP0;
    4'd6: img_pad[6] = (mode[1])? img[14]:FP0;
    endcase
end

always@(*)begin   // 14 15 16 17    20 21 22 23   26 27 28 29    32 33 34 35
    case(cnt[3:0])
    4'd8: img_pad[7] = img[4];
    4'd9: img_pad[7] = img[5];
    4'd10:img_pad[7] = img[6];
    4'd11:img_pad[7] = img[7];

    4'd12:img_pad[7] = img[8];
    4'd13:img_pad[7] = img[9];
    4'd14:img_pad[7] = img[10];
    4'd15:img_pad[7] = img[11];

    4'd0: img_pad[7] = img[12];
    4'd1: img_pad[7] = img[13];
    4'd2: img_pad[7] = img[14];
    4'd3: img_pad[7] = img[15];
    
    4'd4: img_pad[7] = (mode[1])? img[12]:FP0;
    4'd5: img_pad[7] = (mode[1])? img[13]:FP0;
    4'd6: img_pad[7] = (mode[1])? img[14]:FP0;
    4'd7: img_pad[7] = (mode[1])? img[15]:FP0;
    endcase
end

always@(*)begin   //  15 16 17 18   21 22 23 24  27 28 29 30   33 34 35 36
    case(cnt[3:0])
    4'd9: img_pad[8] = img[5];
    4'd10:img_pad[8] = img[6];
    4'd11:img_pad[8] = img[7];
    4'd12:img_pad[8] = (mode[1])? img[7]:FP0;

    4'd13:img_pad[8] = img[9];
    4'd14:img_pad[8] = img[10];
    4'd15:img_pad[8] = img[11];
    4'd0: img_pad[8] = (mode[1])? img[11]:FP0;

    4'd1: img_pad[8] = img[13];
    4'd2: img_pad[8] = img[14];
    4'd3: img_pad[8] = img[15];
    4'd4: img_pad[8] = (mode[1])? img[15]:FP0;

    4'd5: img_pad[8] = (mode[1])? img[13]:FP0;
    4'd6: img_pad[8] = (mode[1])? img[14]:FP0;
    4'd7: img_pad[8] = (mode[1])? img[15]:FP0;
    4'd8: img_pad[8] = (mode[1])? img[15]:FP0;
    endcase
end

always@(posedge clk)begin
    img_pad_3to0 <= img_pad[3];
    img_pad_4to1 <= img_pad[4];
    img_pad_5to2 <= img_pad[5];
    img_pad_6to3 <= img_pad[6];
    img_pad_7to4 <= img_pad[7];
    img_pad_8to5 <= img_pad[8];
end
//=================
// Convolution
//=================

//convolution pipeline 9 stage

add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_0(.clk(clk),.a(conv_refill),.ifm(img_pad[0]),.inw(kernel_1[0]),.out(conv_0));
add_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_1(.clk(clk),.a(conv_0),.ifm(img_pad[1]),.inw(kernel_1[1]),.out(conv_1));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_2(.clk(clk),.a(conv_1),.ifm(img_pad[2]),.inw(kernel_1[2]),.out(conv_2));        
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_3(.clk(clk),.a(conv_2),.ifm(img_pad[3]),.inw(kernel_1[3]),.out(conv_3));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_4(.clk(clk),.a(conv_3),.ifm(img_pad[4]),.inw(kernel_1[4]),.out(conv_4));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_5(.clk(clk),.a(conv_4),.ifm(img_pad[5]),.inw(kernel_1[5]),.out(conv_5));     
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_6(.clk(clk),.a(conv_5),.ifm(img_pad[6]),.inw(kernel_1[6]),.out(conv_6));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_7(.clk(clk),.a(conv_6),.ifm(img_pad[7]),.inw(kernel_1[7]),.out(conv_7));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    u_add_mult_8(.clk(clk),.a(conv_7),.ifm(img_pad[8]),.inw(kernel_1[8]),.out(conv_8));     

always@(posedge clk) begin
    conv_buffer[6] <= conv_8;
    for(i=0;i<6;i=i+1)
        conv_buffer[i] <= conv_buffer[i+1];
end

assign conv_refill = (cnt > 16  )? conv_buffer[0] : FP0;
// first output:  counter == 42 conv_8  ~~~ counter = 57

//=================
// Max pooling
//=================
// maxpooling 0 1 4 5     at counter 47,  48
// maxpooling 2 3 6 7     at counter 49   50
// maxpooling 8 9 12 13   at counter 55   56
// maxpooling 10 11 14 15 at counter 57   58
wire [inst_sig_width + inst_exp_width:0] in_cmp_mp1, in_cmp_mp2;
wire [inst_sig_width + inst_exp_width:0] in_cmp_mp3, in_cmp_mp4;
assign in_cmp_mp1=(cnt[0])? conv_8:conv_buffer[6];
assign in_cmp_mp2=(cnt[0])? conv_buffer[6]:conv_buffer[5];
assign in_cmp_mp3=(cnt[0])? conv_buffer[2]:conv_buffer[1];
assign in_cmp_mp4=(cnt[0])? conv_buffer[3]:conv_buffer[2];

DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    mp_C0 (.a(in_cmp_mp1), .b(in_cmp_mp2), .zctr(1'd0), .z1(max_mp_temp1));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    mp_C1 (.a(in_cmp_mp3), .b(in_cmp_mp4), .zctr(1'd0), .z1(max_mp_temp2));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    mp_C2 (.a(max_mp_temp1), .b(max_mp_temp2), .zctr(1'd0), .z1(max_mp));


//=================
// Fully Connected
//=================
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fc_M1 ( .a(max_mp), .b(in_fc_mult1), .rnd(3'd0), .z(out_fc_mult1), .status( ) );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fc_A1 ( .a(out_fc_mult1), .b(in_fc_add1), .rnd(3'd0),.z(out_fc_add1), .status() );
 
//47  mp1* W[0] put at fc[0]                  101111
//48  mp1* W[1] put at fc[1]                  110000
//49  mp2* W[2] ,plus fc[0] and store fc[0]   110001
//50  mp2* W[3] ,plus fc[1] and store fc[1]   110010
//55  mp3* W[0] put at fc[2]                  110111
//56  mp3* W[1] put at fc[3]                  111000
//57  mp4* W[2] ,plus fc[2] and store fc[2]   111001
//58  mp4* W[3] ,plus fc[3] and store fc[3]   111010

always@(*)begin
    case(cnt[1:0])
    2'd3: in_fc_mult1 = weight[0];
    2'd0: in_fc_mult1 = weight[1];
    2'd1: in_fc_mult1 = weight[2];
    2'd2: in_fc_mult1 = weight[3];
    endcase
end

always@(*)begin
    if(cnt==49)  in_fc_add1 = fc[0];
    else if(cnt==50)  in_fc_add1 = fc[1];
    else if(cnt==57) in_fc_add1 = fc[2];
    else  in_fc_add1 = fc[3];
end

always@(posedge clk)begin
    if(cnt == 47) begin 
        fc[0] <= out_fc_mult1;
    end
    else if (cnt == 49) begin
        fc[0] <= out_fc_add1;
    end
    else begin
        fc[0] <= fc[0];
    end
end


always@(posedge clk)begin
    if(cnt == 48) begin 
        fc[1] <= out_fc_mult1;
    end
    else if (cnt == 50) begin
        fc[1] <= out_fc_add1;
    end
    else begin
        fc[1] <= fc[1];
    end
end

always@(posedge clk)begin
    if(cnt == 55) begin 
        fc[2] <= out_fc_mult1;
    end
    else if (cnt == 57) begin
        fc[2] <= out_fc_add1;
    end
    else begin
        fc[2] <= fc[2];
    end
end

always@(posedge clk)begin
    if(cnt == 56) begin 
        fc[3] <= out_fc_mult1;
    end
    else if (cnt == 58) begin
        fc[3] <= out_fc_add1;
    end
    else begin
        fc[3] <= fc[3];
    end
end



//=================
// Normalization
//=================
//max min
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
norm_c1 ( .a(fc[0]), .b(fc[1]), .zctr(1'b1), .aeqb(), .altb(order[3]), .agtb(), .unordered(), .z0(max_n_temp1), .z1(min_n_temp1), .status0(), .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
norm_c2 ( .a(fc[2]), .b(fc[3]), .zctr(1'b1), .aeqb(), .altb(order[2]), .agtb(), .unordered(), .z0(max_n_temp2), .z1(min_n_temp2), .status0(), .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
norm_c3 ( .a(max_n_temp1), .b(max_n_temp2), .zctr(1'b1), .aeqb(), .altb(order[1]), .agtb(), .unordered(), .z0(max_n), .z1(), .status0(), .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
norm_c4 ( .a(min_n_temp1), .b(min_n_temp2), .zctr(1'b1), .aeqb(), .altb(order[0]), .agtb(), .unordered(), .z0(), .z1(min_n), .status0(), .status1() );

always@(*)begin
    case (order)    // 12 * 2    23*4   01*4   03*2   13*2   02*2
    4'b0000   :begin  //  0 > 1 , 2 >3  , 0 >2 , 1 >3  max0 , min3
        x1 = fc[1];
        x2 = fc[2];
    end 
    4'b0001:begin   // 0 > 1 , 2 >3  , 0 >2 , 1 < 3
        x1 = fc[2];
        x2 = fc[3];
    end
    4'b0010:begin   // 0 > 1 , 2 >3  , 0 < 2 , 1 >3   max 2 , min3
        x1= fc[0];
        x2 = fc[1];
    end
    4'b0011:begin   // 0 > 1 , 2 >3  , 0 < 2 , 1 < 3  max 2 , min1
        x1 = fc[0];
        x2 = fc[3];
    end
    4'b0100:begin   // 0 > 1 , 2 <3  , 0 > 3 , 1 >2  max 0 , min2
        x1 = fc[1];
        x2 = fc[3];
    end
    4'b0101:begin   // 0 > 1 , 2 <3  , 0 > 3 , 1 <2  max 0 , min1
        x1 = fc[2];
        x2 = fc[3];
    end
    4'b0110:begin   // 0 > 1 , 2 <3  , 0 < 3 , 1 >2  max 3 , min2
        x1 = fc[0];
        x2 = fc[1];
    end
    4'b0111:begin   // 0 > 1 , 2 <3  , 0 < 3 , 1 <2  max 3 , min1
        x1 = fc[0];
        x2 = fc[2];
    end
    4'b1000:begin   // 0 < 1 , 2 >3  , 1 > 2 , 0 >3  max 1 , min3
        x1 = fc[0];
        x2 = fc[2];
    end
    4'b1001:begin  // 0 < 1 , 2 >3  , 1 > 2 , 0 <3  max 1 , min0
        x1 = fc[2];
        x2 = fc[3];
    end
    4'b1010:begin  // 0 < 1 , 2 >3  , 1 < 2 , 0 >3  max 2 , min3
        x1 = fc[0];
        x2 = fc[1];
    end
    4'b1011:begin // 0 < 1 , 2 >3  , 1 < 2 , 0 <3  max 2 , min0
        x1 = fc[1];
        x2 = fc[3];
    end
    4'b1100:begin // 0 < 1 , 2 <3  , 1 > 3 , 0 >2  max 1 , min2
        x1 = fc[0];
        x2 = fc[3];
    end
    4'b1101:begin // 0 < 1 , 2 <3  , 1 > 3 , 0 <2  max 1 , min0
        x1 = fc[2];
        x2 = fc[3];
    end
    4'b1110:begin // 0 < 1 , 2 <3  , 1 < 3 , 0 >2  max 3 , min2
        x1 = fc[0];
        x2 = fc[1];
    end
    4'b1111:begin // 0 < 1 , 2 <3  , 1 < 3 , 0 <2  max 3 , min0
        x1 = fc[1];
        x2 = fc[2];
    end
    endcase
end

//=================

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    NA_A1 ( .a(norm_act_in_1), .b(norm_act_in_2), .rnd(3'd0),.z(norm_act_out1), .status() );
    DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    NA_A2 ( .a(norm_act_in_3), .b(norm_act_in_4), .rnd(3'd0),.z(norm_act_out2), .status() );


always@(*)begin
    if(cnt == 59)
    norm_act_in_1 = x1;
    else if(cnt == 60)
    norm_act_in_1 = x2;
    else norm_act_in_1 = act_exp;
end

always@(*)begin
    if(cnt == 59|| cnt == 60)
    norm_act_in_2 = min_n;
    else norm_act_in_2 = FP1;
end

always@(*)begin
    if(cnt == 59|| cnt == 60) norm_act_in_3 = max_n;
    else norm_act_in_3 = act_exp;
end

always@(*)begin
    if(cnt == 59|| cnt == 60) norm_act_in_4 = min_n;
    else norm_act_in_4 = FP_minus1;
end
//addsub output reg
always@(posedge clk)begin
    norm_act_addsub_top <= (mode == 2 && (cnt == 62||cnt == 63))? FP1 : norm_act_out1;
    norm_act_addsub_bot <= norm_act_out2;
end
//div  &&  ln 
/*
always@(*)begin
    if(mode == 2 && (cnt == 63||cnt == 64))  begin//sigmoid
        div_top = FP1; 
    end
    else begin
       div_top = norm_act_addsub_top;   //tanh 
    end
    
end*/
always@(*)begin
        div_top = norm_act_addsub_top;  //sigm & tanh & ln  & normilization
        div_bot = norm_act_addsub_bot;  //sigm & tanh & ln  & normilization
end

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
 u_div( .a(div_top), .b(div_bot), .rnd(3'd0), .z(div_out), .status());
//ln
 DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_extra_prec,inst_arch)
 LN_1 (.a(div_bot),.z(ln_out),.status());

//div or ln  output reg
always@(posedge clk) begin
    if(cnt > 61 && mode == 0) norm_act_div <= norm_act_div;
    else  if(mode==3 && (cnt==63||cnt==64)) norm_act_div <= ln_out;
    else  if(cnt>64) norm_act_div <= norm_act_div;
    else  norm_act_div <= div_out;
end


//exp part//  +z  -z   z*2  and exp(z) one cycle

wire [7:0] z2;
assign z2 = norm_act_div[30:23] + 1;
assign exp_in = (mode==1)?{norm_act_div[31],z2,norm_act_div[22:0]}:(mode==2)? {~norm_act_div[31],norm_act_div[30:0]}:norm_act_div;//(&mode)? norm_act_div: (mode[1])? {~norm_act_div[31],norm_act_div[30:0]} : z_2; 

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
 u_EXP (.a(exp_in),.z(exp_out),.status() );

always@(posedge clk)begin
    act_exp <= exp_out;
end



//=================
// Output control
//=================


always@(posedge clk) begin
    if(cnt == 61) norm_act_div1 <= norm_act_div;
    else if(cnt == 64 ) norm_act_div1 <= norm_act_div;//&& mode != 0) norm_act_div1 <= norm_act_div;
    else norm_act_div1 <= norm_act_div1;
end


assign n_cnt_out = (out_flag)? cnt_out + 1:cnt_out;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        cnt_out <= 0;
    end
    else cnt_out <= n_cnt_out;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) out_flag <= 0;
    else if(mode ==0 && cnt == 60) out_flag <= 1;
    else if(mode ==0 && cnt == 64) out_flag <= 0;
    else if(cnt == 63) out_flag <= 1;
    else if(cnt == 67) out_flag <= 0; 
    else out_flag <= out_flag;
end 


assign activation_0 = (mode ==2)?FP_SIGM_0:(mode ==3)? FP_SOFTP_0:FP0;
assign activation_1 = (mode ==0)?FP1:(mode ==1)? FP_TANH_1:(mode ==2)?FP_SIGM_1:FP_SOFTP_1;

always@(*)begin
    if(order == 0 || order == 1 || order == 4 || order == 5) n_output[0] = activation_1;
    else if(order == 9 || order == 11|| order == 13|| order ==15) n_output[0] = activation_0;
    else n_output[0] = norm_act_div;
end

always@(*)begin
    if(order == 8 || order == 9 || order == 12 || order == 13) n_output[1] = activation_1;   
    else if(order == 1 || order == 3|| order == 5|| order ==7) n_output[1] = activation_0;
    else if(order == 2 || order == 6|| order == 10|| order ==14) n_output[1] = norm_act_div;
    else n_output[1] = norm_act_div1;
end


always@(*)begin
    if(order == 2 || order == 3 || order == 10 || order == 11) n_output[2] = activation_1;   
    else if(order == 4 || order == 6|| order == 12|| order ==14) n_output[2] = activation_0;
    else if(order == 0 || order == 7|| order == 8|| order ==15) n_output[2] = norm_act_div; 
    else n_output[2] = norm_act_div1;
end

always@(*)begin
    if(order == 6 || order == 7 || order == 14 || order == 15) n_output[3] = activation_1;
    else if(order == 0 || order == 2|| order == 8|| order ==10) n_output[3] = activation_0;
    else n_output[3] = norm_act_div;
end



//=================
// Output
//=================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else if(out_flag) begin
        out_valid <= 1;
        out <= n_output[cnt_out];
    end
    else  begin
        out_valid <= 0;
        out <= 0;
    end
end

endmodule


module add_mult 
    #(  parameter inst_sig_width       = 23,
        parameter inst_exp_width       = 8,
        parameter inst_ieee_compliance = 0
    )(clk,a,ifm,inw,out);
    
    input clk;
    input [inst_sig_width +inst_exp_width :0] a, ifm, inw;
    output reg [inst_sig_width +inst_exp_width :0] out;

    wire [inst_sig_width +inst_exp_width :0] mult_temp ,add_temp;

    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        u_M1( .a(ifm), .b(inw), .rnd(3'd0), .z(mult_temp), .status( ) );

    DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        u_A1 ( .a(a), .b(mult_temp),.op(1'b0), .rnd(3'd0),.z(add_temp), .status() );
    
    always@(posedge clk) out <= add_temp;

endmodule