//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab05 Exercise		: CAD
//   Author     		: Tse-Chun Hsu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CAD.v
//   Module Name : CAD
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CAD(
    //Input Port
    clk,
    rst_n,
	in_valid,
    in_valid2,
    matrix,
    matrix_idx,
    matrix_size,
    mode,

    //Output Port
    out_valid,
    out_value
    );

input              clk, rst_n, in_valid, in_valid2, mode;
input signed [1:0] matrix_size;
input signed [3:0] matrix_idx;
input signed [7:0] matrix;  

output reg out_valid;
output reg out_value;
//==============================================//
//             Parameter and Integer            //
//==============================================//
integer i;
genvar r;
 //FSM
parameter IDLE = 4'd0;
parameter STORE_IMG = 4'd1;
parameter STORE_KERNEL = 4'd2;
parameter CONV = 4'd3;
parameter DECONV = 4'd4;
parameter WAIT = 4'd5;
parameter OUT_STATE = 4'd6;
parameter MAX_POOLING = 4'd7;
parameter LOAD_WORD = 4'd8;
reg [3:0] c_state,n_state;
//==============================================//
//                 reg declaration              //
//==============================================//
//constant
reg [4:0] row_bound;
reg [2:0] word_bound;
reg [1:0] size;
reg mode_reg;
reg [3:0] img_index,kernel_index;
reg [5:0] conv_size;
reg [5:0] conv_row_end;
reg [5:0] EXE_DECONV;
//cnt
//for write sram
reg [2:0] cnt_in;
reg [1:0] cnt_word;
reg [4:0] cnt_row;
reg [3:0] cnt_img;
reg [6:0] cnt_word_kernel;
//sram port
reg [10:0] ADR_IMG;
reg [6:0] ADR_KER;
wire [63:0] DATA_IMG_in;
wire [39:0] DATA_KER_in;
reg [7:0] IMG_in [0:7];
reg [7:0] KER_in [0:4];
wire [63:0] DATA_IMG_out;
wire [39:0] DATA_KER_out;
wire WEB_KER_en;
wire WEB_en;

///conv control
reg [5:0] cnt_conv_row,cnt_conv_col;  //for conv後的ROW COLUMN
reg [2:0] cnt_conv;                   // FSM 的counter:deconv conv cocunter
reg [1:0] cnt_conv_word;              // read SRAM的 word
reg [4:0] cnt_out;       
//SRAM img       
wire [5:0] sram_row;
wire [3:0] sram_img;
//conv mux
reg signed[7:0] img1[0:7];
reg signed[7:0] img2[0:7];
reg signed[7:0] img3[0:7];
reg signed[7:0] img4[0:7];
reg signed[7:0] img5[0:7]; 
reg signed[7:0] img6[0:7];
reg signed[7:0] ker[0:4];
reg signed[7:0] img_shift_2[0:1];
reg signed[7:0] img_shift_1;
//conv ctr
reg zero_flag;
reg shift_word_flag;
//conv&&maxpooling 
reg  signed[19:0] conv_temp1,conv_temp2,conv_temp3,conv_temp4;
wire [19:0] in_temp1,in_temp2,in_temp3,in_temp4;
wire [19:0] out_temp1,out_temp2,out_temp3,out_temp4;
wire signed[19:0]  max_temp1,max_temp2,max_out;
//pre output
reg [19:0] n_output;
reg [19:0] n_output_reg , n_output_reg_next;

//==============================================//
//                 ur design                    //
//==============================================//

//======================================
//    FSM
//======================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  c_state <= IDLE;
    else c_state <= n_state;
end

always@(*)begin
    case (c_state)
        IDLE:begin
            if(in_valid) n_state = STORE_IMG;
            else if(in_valid2)  begin
                if(mode) n_state = DECONV;
                else n_state = CONV;
            end
            else n_state = IDLE;
        end 
        STORE_IMG:begin
            if(cnt_img == 15 && cnt_row == row_bound && cnt_word == word_bound && cnt_in ==7) n_state = STORE_KERNEL;
            else n_state = STORE_IMG;
        end
        STORE_KERNEL:begin
            if(cnt_word_kernel == 79 && cnt_in ==4) n_state = IDLE;
            else n_state = STORE_KERNEL;
        end
        CONV:begin
            if(cnt_conv==7) n_state = MAX_POOLING;
            else n_state = CONV;
        end

        MAX_POOLING:begin
            if( ~|cnt_out) n_state = OUT_STATE;
            else n_state = WAIT;
        end
        WAIT:begin
            if( ~|cnt_out) n_state = OUT_STATE;
            else n_state = WAIT;
        end
        DECONV:begin
            if(cnt_conv == 7 && ~|cnt_out) n_state = OUT_STATE;
            else if(cnt_conv==7) n_state = WAIT;
            else n_state = DECONV;
        end
        OUT_STATE:begin
            /*
            if(mode_reg == 0) begin
                if(cnt_conv_row == conv_row_end && cnt_conv_col == 0) n_state = IDLE;
                else n_state = CONV;
            end
            else begin 
                if(cnt_conv_row == conv_row_end && cnt_conv_col == 0) n_state = IDLE;
                else n_state = DECONV;
            end*/
            if(cnt_conv_row == conv_row_end) n_state = IDLE;
            else if(mode_reg) n_state = DECONV;
            else n_state = CONV;

        end
        default:  n_state = IDLE;
    endcase
end
//======================================
//    UNIVERSAL INPUT MODE 
//======================================

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  size <= 0;
    else if(in_valid && c_state==IDLE)     size <= matrix_size;
    else size <= size;
end



always@(posedge clk) begin
    if(in_valid2 && c_state==IDLE) img_index <= matrix_idx;
    else if( (c_state==CONV||c_state==DECONV) && in_valid2) kernel_index <= matrix_idx;
    else begin 
        kernel_index <= kernel_index;
        img_index <= img_index;
    end
end

always@(posedge clk)begin
    if(in_valid2 && c_state==IDLE) mode_reg <= mode;
    else mode_reg <= mode_reg;
end
//sram write row control
always@(*)begin
    if(size==0) row_bound = 7;
    else if(size==1) row_bound = 15;
    else row_bound = 31;
end

//sram write word control
always@(*)begin
    if(size==0) word_bound = 0;
    else if(size==1) word_bound = 1;
    else word_bound = 3;
end

always@(*)begin
    case (size)
        2'd0:begin
            conv_size = (mode_reg)?11:1;
        end
        2'd1: begin
            conv_size =(mode_reg)?19: 5;
        end
        default: begin
            conv_size = (mode_reg)?35:13;
        end
    endcase
end

always@(*)begin
    if(size==0) conv_row_end =(mode_reg)?12: 2;
    else if(size==1) conv_row_end =(mode_reg)? 20:6;
    else conv_row_end =(mode_reg)?36: 14;
end


//======================================
//    SRAM WRIRE control
//======================================
//==============================================//  SRAM IMG counter 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_in <= 0;
    else if(c_state == STORE_KERNEL && cnt_in == 4) cnt_in <= 0;
    else if(in_valid)   cnt_in <= cnt_in + 1;
    else cnt_in <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )  cnt_word <= 0;
    else if((cnt_word == word_bound && &cnt_in ) ) cnt_word <= 0;
    else if(&cnt_in )   cnt_word <= cnt_word + 1;  
    else cnt_word <= cnt_word;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_row <= 0;
    else if(cnt_row == row_bound && cnt_word == word_bound && &cnt_in) cnt_row <= 0;
    else if(cnt_word == word_bound && &cnt_in)   cnt_row <= cnt_row + 1;
    else cnt_row <= cnt_row;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_img <= 0;
    else if(cnt_row == row_bound && cnt_word == word_bound && &cnt_in) cnt_img <= cnt_img + 1;
    else cnt_img <= cnt_img;
end


assign WEB_en = (c_state == STORE_IMG && &cnt_in)? 0:1;
assign DATA_IMG_in = {IMG_in[0],IMG_in[1],IMG_in[2],IMG_in[3],IMG_in[4],IMG_in[5],IMG_in[6],IMG_in[7]};

//data_in 
always@(*)begin
    IMG_in[7] = matrix;
end
always@(posedge clk)begin
    for(i=0;i<7;i=i+1)  IMG_in[i] <= IMG_in[i+1];
end



//
//==============================================//  SRAM KERNEL counter 

assign WEB_KER_en = (c_state == STORE_KERNEL && cnt_in ==4)? 0:1;
assign DATA_KER_in = {IMG_in[3],IMG_in[4],IMG_in[5],IMG_in[6],IMG_in[7]};

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_word_kernel <= 0;
    else if(cnt_in == 4 && n_state == STORE_KERNEL)   cnt_word_kernel <= cnt_word_kernel + 1;
    else if( c_state==IDLE) cnt_word_kernel <= 0;
    else cnt_word_kernel <= cnt_word_kernel;
end


//======================================
//      convultion mux
//======================================


always@(*)begin
    if(size==1 && cnt_conv_col>12) zero_flag = 1;
    else if(size==2 && cnt_conv_col>28) zero_flag = 1;
    else if(size==0 && cnt_conv_col>4) zero_flag = 1;
    else zero_flag = 0;
end
always@(*)begin
    if(cnt_conv_col[1:0]==1)begin
        img_shift_2[0] = DATA_IMG_out[63:56];
        img_shift_2[1] = DATA_IMG_out[55:48];
    end
    else if(cnt_conv_col[1:0]==2)begin
        img_shift_2[0] = DATA_IMG_out[47:40];
        img_shift_2[1] = DATA_IMG_out[39:32];
    end
    else begin
        img_shift_2[0] = DATA_IMG_out[31:24];
        img_shift_2[1] = DATA_IMG_out[23:16];
    end
end
//deconv
always@(*)begin
    //if(!rst_n) shift_word_flag = 0;
    if(cnt_conv_col == 4 || cnt_conv_col == 12 ||cnt_conv_col == 20) shift_word_flag = 1;
    else shift_word_flag = 0;
end

always@(*)begin
    if(zero_flag)    img_shift_1 = 0;
    else if(cnt_conv_col[2:0]==1)  img_shift_1 = DATA_IMG_out[31:24];
    else if(cnt_conv_col[2:0]==2)  img_shift_1 = DATA_IMG_out[23:16];
    else if(cnt_conv_col[2:0]==3)  img_shift_1 = DATA_IMG_out[15:8];
    else if(cnt_conv_col[2:0]==4)  img_shift_1 = DATA_IMG_out[7:0];
    else if(cnt_conv_col[2:0]==5)  img_shift_1 = DATA_IMG_out[63:56];  //new word in
    else if(cnt_conv_col[2:0]==6)  img_shift_1 = DATA_IMG_out[55:48];
    else if(cnt_conv_col[2:0]==7)  img_shift_1 = DATA_IMG_out[47:40];
    else   img_shift_1 = DATA_IMG_out[39:32];
end
//conv/ deconv共用reg
always@(posedge clk)begin
    if(c_state == CONV && n_state == CONV) begin                 //conv 直接shift 2
        if(cnt_conv_col[1:0]==0) begin
            img1[0] <= DATA_IMG_out[63:56];
            img1[1] <= DATA_IMG_out[55:48];
            img1[2] <= DATA_IMG_out[47:40];
            img1[3] <= DATA_IMG_out[39:32];
            img1[4] <= DATA_IMG_out[31:24];
            img1[5] <= DATA_IMG_out[23:16];
            img1[6] <= DATA_IMG_out[15:8];
            img1[7] <= DATA_IMG_out[7:0];
        end
        else begin
            img1[0] <= img6[2];
            img1[1] <= img6[3];
            img1[2] <= img6[4];
            img1[3] <= img6[5];
            img1[4] <= img6[6];
            img1[5] <= img6[7];
            img1[6] <= img_shift_2[0];
            img1[7] <= img_shift_2[1];
        end
    end
    else if(c_state == DECONV && n_state == DECONV)begin
        if(cnt_conv_row > row_bound && sram_row >= row_bound)begin        //最後四個row padding 0
            for(i=0;i<8;i=i+1) img1[i] <= 0;
        end
        else if(cnt_conv_col==0)begin     //一開始padding四個0
            img1[0] <= 0;
            img1[1] <= 0;
            img1[2] <= 0;
            img1[3] <= 0;
            img1[4] <= DATA_IMG_out[63:56];
            img1[5] <= DATA_IMG_out[55:48];
            img1[6] <= DATA_IMG_out[47:40];
            img1[7] <= DATA_IMG_out[39:32];
        end
        else begin                       //shift 1,load新的word
            img1[0] <= img6[1];
            img1[1] <= img6[2];
            img1[2] <= img6[3];
            img1[3] <= img6[4];
            img1[4] <= img6[5];
            img1[5] <= img6[6];
            img1[6] <= img6[7];
            img1[7] <= img_shift_1;
        end
    end
    else begin
        for(i=0;i<8;i=i+1) img1[i] <= img1[i];
    end
end


generate
    for(r=0;r<8;r=r+1) begin
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                img2[r] <= 0;
                img3[r] <= 0;
                img4[r] <= 0;
                img5[r] <= 0;
                img6[r] <= 0;
            end
            else if((c_state == CONV && n_state == CONV) ||c_state == DECONV && n_state == DECONV) begin
                img2[r] <= img1[r];
                img3[r] <= img2[r];
                img4[r] <= img3[r];
                img5[r] <= img4[r];
                img6[r] <= img5[r];
            end
        end
    end
endgenerate


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for (i=0;i<5;i=i+1)begin
            ker[i] <= 0;
        end
    end
    else if(c_state == CONV) begin
        ker[0] <= DATA_KER_out[39:32];
        ker[1] <= DATA_KER_out[31:24];
        ker[2] <= DATA_KER_out[23:16];
        ker[3] <= DATA_KER_out[15:8];
        ker[4] <= DATA_KER_out[7:0];
    end
    else if(c_state == DECONV)begin
        ker[0] <= DATA_KER_out[7:0];
        ker[1] <= DATA_KER_out[15:8];
        ker[2] <= DATA_KER_out[23:16];
        ker[3] <= DATA_KER_out[31:24];
        ker[4] <= DATA_KER_out[39:32];
    end
end
//======================================
//    CONV counter control
//======================================

// conv_row conv_col counter 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_conv_col <= 0; 
    else if(n_state == OUT_STATE && cnt_conv_col == conv_size) cnt_conv_col <= 0;
    else if(n_state == OUT_STATE) cnt_conv_col <= cnt_conv_col + 1;
    else cnt_conv_col <= cnt_conv_col;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_conv_row <= 0;
    else if(n_state == OUT_STATE && cnt_conv_col == conv_size) cnt_conv_row <= cnt_conv_row + 1;
    else if(n_state == IDLE) cnt_conv_row <= 0;
    else cnt_conv_row <= cnt_conv_row;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_conv <= 0;
    else if(n_state == CONV || n_state == DECONV) cnt_conv <= cnt_conv + 1;
    else cnt_conv <= 0;
end

//word counter
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_conv_word <= 0;
    else if(mode_reg == 0 && cnt_conv_col[1:0]==0 && n_state == OUT_STATE) cnt_conv_word <= cnt_conv_word + 1;
    else if(mode_reg == 1 && shift_word_flag && n_state == OUT_STATE) cnt_conv_word <= cnt_conv_word + 1;
    else if(cnt_conv_col == conv_size &&  n_state == OUT_STATE) cnt_conv_word <= 0;
    else cnt_conv_word <= cnt_conv_word;
end
//FSM　DECONV cycle ending
always@(*)begin
    if(cnt_conv_row==0) EXE_DECONV = 3;
    else if(cnt_conv_row == 1) EXE_DECONV=4;
    else if(cnt_conv_row == 2) EXE_DECONV=5;
    else if(cnt_conv_row == 3) EXE_DECONV=6;
    else EXE_DECONV = 7;
end
//====================================== 
//      colvolution part
//======================================

always@(posedge clk )begin
    conv_temp1 <= out_temp1;
    conv_temp2 <= out_temp2;
    conv_temp3 <= out_temp3;
    conv_temp4 <= out_temp4;
end


assign in_temp1 = (cnt_conv == 3)? 0:conv_temp1;
assign in_temp2 = (cnt_conv == 3)? 0:conv_temp2;
assign in_temp3 = (cnt_conv == 3)? 0:conv_temp3;
assign in_temp4 = (cnt_conv == 3)? 0:conv_temp4;
add_mult ma1 (.img1(img1[0]) ,.img2(img1[1]) ,.img3(img1[2]) ,.img4(img1[3]) ,.img5(img1[4]) ,.ker1(ker[0]) ,.ker2(ker[1]) ,.ker3(ker[2]) ,.ker4(ker[3]) ,.ker5(ker[4]) ,.in(in_temp1) ,.out(out_temp1));
add_mult ma2 (.img1(img1[1]) ,.img2(img1[2]) ,.img3(img1[3]) ,.img4(img1[4]) ,.img5(img1[5]) ,.ker1(ker[0]) ,.ker2(ker[1]) ,.ker3(ker[2]) ,.ker4(ker[3]) ,.ker5(ker[4]) ,.in(in_temp2) ,.out(out_temp2));
add_mult ma3 (.img1(img2[0]) ,.img2(img2[1]) ,.img3(img2[2]) ,.img4(img2[3]) ,.img5(img2[4]) ,.ker1(ker[0]) ,.ker2(ker[1]) ,.ker3(ker[2]) ,.ker4(ker[3]) ,.ker5(ker[4]) ,.in(in_temp3) ,.out(out_temp3));
add_mult ma4 (.img1(img2[1]) ,.img2(img2[2]) ,.img3(img2[3]) ,.img4(img2[4]) ,.img5(img2[5]) ,.ker1(ker[0]) ,.ker2(ker[1]) ,.ker3(ker[2]) ,.ker4(ker[3]) ,.ker5(ker[4]) ,.in(in_temp4) ,.out(out_temp4));

//======================================
//      Max Pooling
//======================================

assign max_temp1 = (conv_temp1>conv_temp2)? conv_temp1:conv_temp2; 
assign max_temp2 = (conv_temp3>conv_temp4)? conv_temp3:conv_temp4;
assign max_out = (max_temp1>max_temp2)? max_temp1:max_temp2;

//======================================
//      PRE output
//======================================
always@(*)begin
    if(c_state == DECONV && cnt_conv==EXE_DECONV && ~|cnt_out) n_output = out_temp3; //load DECONV first output
    else if(c_state ==MAX_POOLING && n_state == OUT_STATE) n_output = max_out;                 //load CONV&MP first output
    else if(c_state == WAIT && n_state == OUT_STATE) n_output = n_output_reg_next;        //load next output
    else n_output = n_output_reg;
end

//keep n_output 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) n_output_reg <= 0;                     
    else n_output_reg <= n_output;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) n_output_reg_next <= 0; 
    else if(c_state == DECONV && cnt_conv==EXE_DECONV ) n_output_reg_next <= out_temp3; // keep DECONV next output
    else if(n_state == WAIT && c_state == MAX_POOLING) n_output_reg_next <= max_out; //keep CONV next output
    else n_output_reg_next <= n_output_reg_next;
end



//======================================
//    IMG  SRAM address & data_out 
//======================================
wire [4:0] row_2;
assign row_2 = {cnt_conv_row,1'b0};

assign sram_img = (in_valid2 && c_state==IDLE)?matrix_idx:img_index;
assign sram_row = (n_state == CONV)? row_2 + cnt_conv : cnt_conv_row - cnt_conv;
always@(*)begin
    if(c_state == STORE_IMG)  ADR_IMG = {cnt_img,cnt_row,cnt_word};
    else  ADR_IMG = {sram_img,sram_row[4:0],cnt_conv_word};  
end

IMG_SRAM_2048X64X1BM1 my_IMG_SRAM(.A0(ADR_IMG[0]), .A1(ADR_IMG[1]), .A2(ADR_IMG[2]), .A3(ADR_IMG[3]), .A4(ADR_IMG[4]), .A5(ADR_IMG[5]), .A6(ADR_IMG[6]), .A7(ADR_IMG[7]), .A8(ADR_IMG[8]), .A9(ADR_IMG[9]), .A10(ADR_IMG[10]), 
                                .DO0(DATA_IMG_out[0]), .DO1(DATA_IMG_out[1]), .DO2(DATA_IMG_out[2]), .DO3(DATA_IMG_out[3]), .DO4(DATA_IMG_out[4]), .DO5(DATA_IMG_out[5]), .DO6(DATA_IMG_out[6]), .DO7(DATA_IMG_out[7]), 
                                .DO8(DATA_IMG_out[8]), .DO9(DATA_IMG_out[9]), .DO10(DATA_IMG_out[10]), .DO11(DATA_IMG_out[11]), .DO12(DATA_IMG_out[12]), .DO13(DATA_IMG_out[13]), .DO14(DATA_IMG_out[14]), .DO15(DATA_IMG_out[15]), 
                                .DO16(DATA_IMG_out[16]), .DO17(DATA_IMG_out[17]), .DO18(DATA_IMG_out[18]), .DO19(DATA_IMG_out[19]), .DO20(DATA_IMG_out[20]), .DO21(DATA_IMG_out[21]), .DO22(DATA_IMG_out[22]), .DO23(DATA_IMG_out[23]), 
                                .DO24(DATA_IMG_out[24]), .DO25(DATA_IMG_out[25]), .DO26(DATA_IMG_out[26]), .DO27(DATA_IMG_out[27]), .DO28(DATA_IMG_out[28]), .DO29(DATA_IMG_out[29]), .DO30(DATA_IMG_out[30]), .DO31(DATA_IMG_out[31]), 
                                .DO32(DATA_IMG_out[32]), .DO33(DATA_IMG_out[33]), .DO34(DATA_IMG_out[34]), .DO35(DATA_IMG_out[35]), .DO36(DATA_IMG_out[36]), .DO37(DATA_IMG_out[37]), .DO38(DATA_IMG_out[38]), .DO39(DATA_IMG_out[39]), 
                                .DO40(DATA_IMG_out[40]), .DO41(DATA_IMG_out[41]), .DO42(DATA_IMG_out[42]), .DO43(DATA_IMG_out[43]), .DO44(DATA_IMG_out[44]), .DO45(DATA_IMG_out[45]), .DO46(DATA_IMG_out[46]), .DO47(DATA_IMG_out[47]), 
                                .DO48(DATA_IMG_out[48]), .DO49(DATA_IMG_out[49]), .DO50(DATA_IMG_out[50]), .DO51(DATA_IMG_out[51]), .DO52(DATA_IMG_out[52]), .DO53(DATA_IMG_out[53]), .DO54(DATA_IMG_out[54]), .DO55(DATA_IMG_out[55]), 
                                .DO56(DATA_IMG_out[56]), .DO57(DATA_IMG_out[57]), .DO58(DATA_IMG_out[58]), .DO59(DATA_IMG_out[59]), .DO60(DATA_IMG_out[60]), .DO61(DATA_IMG_out[61]), .DO62(DATA_IMG_out[62]), .DO63(DATA_IMG_out[63]),
                                .DI0(DATA_IMG_in[0]), .DI1(DATA_IMG_in[1]), .DI2(DATA_IMG_in[2]), .DI3(DATA_IMG_in[3]), .DI4(DATA_IMG_in[4]), .DI5(DATA_IMG_in[5]), .DI6(DATA_IMG_in[6]), .DI7(DATA_IMG_in[7]), 
                                .DI8(DATA_IMG_in[8]), .DI9(DATA_IMG_in[9]), .DI10(DATA_IMG_in[10]), .DI11(DATA_IMG_in[11]), .DI12(DATA_IMG_in[12]), .DI13(DATA_IMG_in[13]), .DI14(DATA_IMG_in[14]), .DI15(DATA_IMG_in[15]), 
                                .DI16(DATA_IMG_in[16]), .DI17(DATA_IMG_in[17]), .DI18(DATA_IMG_in[18]), .DI19(DATA_IMG_in[19]), .DI20(DATA_IMG_in[20]), .DI21(DATA_IMG_in[21]), .DI22(DATA_IMG_in[22]), .DI23(DATA_IMG_in[23]), 
                                .DI24(DATA_IMG_in[24]), .DI25(DATA_IMG_in[25]), .DI26(DATA_IMG_in[26]), .DI27(DATA_IMG_in[27]), .DI28(DATA_IMG_in[28]), .DI29(DATA_IMG_in[29]), .DI30(DATA_IMG_in[30]), .DI31(DATA_IMG_in[31]), 
                                .DI32(DATA_IMG_in[32]), .DI33(DATA_IMG_in[33]), .DI34(DATA_IMG_in[34]), .DI35(DATA_IMG_in[35]), .DI36(DATA_IMG_in[36]), .DI37(DATA_IMG_in[37]), .DI38(DATA_IMG_in[38]), .DI39(DATA_IMG_in[39]), 
                                .DI40(DATA_IMG_in[40]), .DI41(DATA_IMG_in[41]), .DI42(DATA_IMG_in[42]), .DI43(DATA_IMG_in[43]), .DI44(DATA_IMG_in[44]), .DI45(DATA_IMG_in[45]), .DI46(DATA_IMG_in[46]), .DI47(DATA_IMG_in[47]), 
                                .DI48(DATA_IMG_in[48]), .DI49(DATA_IMG_in[49]), .DI50(DATA_IMG_in[50]), .DI51(DATA_IMG_in[51]), .DI52(DATA_IMG_in[52]), .DI53(DATA_IMG_in[53]), .DI54(DATA_IMG_in[54]), .DI55(DATA_IMG_in[55]), 
                                .DI56(DATA_IMG_in[56]), .DI57(DATA_IMG_in[57]), .DI58(DATA_IMG_in[58]), .DI59(DATA_IMG_in[59]), .DI60(DATA_IMG_in[60]), .DI61(DATA_IMG_in[61]), .DI62(DATA_IMG_in[62]), .DI63(DATA_IMG_in[63]),
                                .CK(clk), .WEB(WEB_en), .OE(1'b1), .CS(1'b1));
//======================================
//   KERNEL SRAM address & data_out 
//======================================
wire [3:0] sram_ker;
wire [6:0] sram_ker_in;
assign sram_ker = (in_valid2)? matrix_idx : kernel_index;
assign sram_ker_in = sram_ker*5 + cnt_conv - 1;
always@(*)begin
    if(c_state == STORE_KERNEL) ADR_KER = cnt_word_kernel;
    else  ADR_KER = sram_ker_in;
end

                            
SUMA180_80X40X1BM1 my_KERNAL_SRAM (.A0(ADR_KER[0]), .A1(ADR_KER[1]), .A2(ADR_KER[2]), .A3(ADR_KER[3]), .A4(ADR_KER[4]), .A5(ADR_KER[5]), .A6(ADR_KER[6]),
                .DO0(DATA_KER_out[0]), .DO1(DATA_KER_out[1]), .DO2(DATA_KER_out[2]), .DO3(DATA_KER_out[3]), .DO4(DATA_KER_out[4]), .DO5(DATA_KER_out[5]), .DO6(DATA_KER_out[6]), .DO7(DATA_KER_out[7]), 
                .DO8(DATA_KER_out[8]), .DO9(DATA_KER_out[9]), .DO10(DATA_KER_out[10]), .DO11(DATA_KER_out[11]), .DO12(DATA_KER_out[12]), .DO13(DATA_KER_out[13]), .DO14(DATA_KER_out[14]), .DO15(DATA_KER_out[15]), 
                .DO16(DATA_KER_out[16]), .DO17(DATA_KER_out[17]), .DO18(DATA_KER_out[18]), .DO19(DATA_KER_out[19]), .DO20(DATA_KER_out[20]), .DO21(DATA_KER_out[21]), .DO22(DATA_KER_out[22]), .DO23(DATA_KER_out[23]), 
                .DO24(DATA_KER_out[24]), .DO25(DATA_KER_out[25]), .DO26(DATA_KER_out[26]), .DO27(DATA_KER_out[27]), .DO28(DATA_KER_out[28]), .DO29(DATA_KER_out[29]), .DO30(DATA_KER_out[30]), .DO31(DATA_KER_out[31]), 
                .DO32(DATA_KER_out[32]), .DO33(DATA_KER_out[33]), .DO34(DATA_KER_out[34]), .DO35(DATA_KER_out[35]), .DO36(DATA_KER_out[36]), .DO37(DATA_KER_out[37]), .DO38(DATA_KER_out[38]), .DO39(DATA_KER_out[39]), 
                .DI0(DATA_KER_in[0]), .DI1(DATA_KER_in[1]), .DI2(DATA_KER_in[2]), .DI3(DATA_KER_in[3]), .DI4(DATA_KER_in[4]), .DI5(DATA_KER_in[5]), .DI6(DATA_KER_in[6]), .DI7(DATA_KER_in[7]), 
                .DI8(DATA_KER_in[8]), .DI9(DATA_KER_in[9]), .DI10(DATA_KER_in[10]), .DI11(DATA_KER_in[11]), .DI12(DATA_KER_in[12]), .DI13(DATA_KER_in[13]), .DI14(DATA_KER_in[14]), .DI15(DATA_KER_in[15]), 
                .DI16(DATA_KER_in[16]), .DI17(DATA_KER_in[17]), .DI18(DATA_KER_in[18]), .DI19(DATA_KER_in[19]), .DI20(DATA_KER_in[20]), .DI21(DATA_KER_in[21]), .DI22(DATA_KER_in[22]), .DI23(DATA_KER_in[23]), 
                .DI24(DATA_KER_in[24]), .DI25(DATA_KER_in[25]), .DI26(DATA_KER_in[26]), .DI27(DATA_KER_in[27]), .DI28(DATA_KER_in[28]), .DI29(DATA_KER_in[29]), .DI30(DATA_KER_in[30]), .DI31(DATA_KER_in[31]), 
                .DI32(DATA_KER_in[32]), .DI33(DATA_KER_in[33]), .DI34(DATA_KER_in[34]), .DI35(DATA_KER_in[35]), .DI36(DATA_KER_in[36]), .DI37(DATA_KER_in[37]), .DI38(DATA_KER_in[38]), .DI39(DATA_KER_in[39]), 
                .CK(clk), .WEB(WEB_KER_en), .OE(1'b1), .CS(1'b1));


//======================================
//   output control and output
//======================================
//outcnt
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_out <= 0;
    else if(cnt_out == 19) cnt_out <= 0;    
    else if(n_state == OUT_STATE || |cnt_out ) cnt_out <= cnt_out + 1;
    else cnt_out <= 0;
end
//output
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        out_valid <= 0;
        out_value <= 0;
    end
    else if(n_state == OUT_STATE || |cnt_out)begin
        out_valid <= 1;
        out_value <= n_output[cnt_out];
    end
    else begin
        out_valid <= 0;
        out_value <= 0;
    end
end
endmodule


//==========================================================================================================================================================================================================================//
//                                                                                                 submodule                                                                                                                //
//==========================================================================================================================================================================================================================//

module add_mult(img1,img2,img3,img4,img5,ker1,ker2,ker3,ker4,ker5,in,out);
    input signed[7:0] img1,img2,img3,img4,img5,ker1,ker2,ker3,ker4,ker5;
    input signed[19:0] in;
    output signed [19:0] out;

    wire signed[15:0] mult1,mult2,mult3,mult4,mult5;

    assign mult1 = img1*ker1;
    assign mult2 = img2*ker2;
    assign mult3 = img3*ker3;
    assign mult4 = img4*ker4;
    assign mult5 = img5*ker5;

    assign out = in + mult1 + mult2 + mult3 + mult4 + mult5;

    /*
    wire [119:0] dw_sum_in;
    assign dw_sum_in = {in,{{mult1[15]}*4, mult1}, {{mult2[15]}*4, mult2}, {{mult3[15]}*4, mult3}, {{mult4[15]}*4, mult4}, {{mult5[15]}*4, mult5}};

    DW02_sum #(6, 20) u_DW02_sum
    (
        .INPUT(dw_sum_in      ),
        .SUM  (out     )
    );*/

endmodule