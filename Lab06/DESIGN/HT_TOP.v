//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid;
output reg out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
integer i;
reg [3:0] cnt_in;
reg [1:0] cnt_encode;
reg [2:0] cnt_out;
reg [2:0] length;
//input
reg [4:0] weight[0:7];
reg [4:0] n_weight[0:7];
reg [3:0] addr [0:7]; 
reg [3:0] n_addr [0:7];
//sort2

//encode
reg [3:0] addr_encode_1[0:7];
reg [4:0] weight_encode_1[0:7];
reg [3:0] addr_encode_2[0:7];
reg [4:0] weight_encode_2[0:7];
//

// ===============================================================
// Design
// ===============================================================
parameter IDLE = 3'd0;
parameter INPUT = 3'd1;
parameter ENCODE = 3'd2;
parameter OUTPUT1 = 3'd3;
parameter OUTPUT2 = 3'd4;
parameter OUTPUT3 = 3'd5;
parameter OUTPUT4 = 3'd6;
parameter OUTPUT5 = 3'd7;

reg [2:0] n_state,c_state;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  c_state <= IDLE;
    else c_state <= n_state; 
end

always@(*)begin
    case(c_state)
        IDLE:begin
            if(in_valid)  n_state = INPUT;
            else n_state = IDLE;
        end
        INPUT:begin
            if(cnt_in[3])n_state = ENCODE;
            else n_state = INPUT;
        end
        ENCODE:begin
            if(cnt_encode == 3) n_state = OUTPUT1;
            else n_state = ENCODE;
        end
        OUTPUT1:begin
            if(cnt_out == length ) n_state = OUTPUT2;
            else n_state = OUTPUT1;
        end
        OUTPUT2:begin
            if(cnt_out == length ) n_state = OUTPUT3;
            else n_state = OUTPUT2;
        end
        OUTPUT3:begin
            if(cnt_out == length ) n_state = OUTPUT4;
            else n_state = OUTPUT3;
        end
        OUTPUT4:begin
            if(cnt_out == length ) n_state = OUTPUT5;
            else n_state = OUTPUT4;
        end
        OUTPUT5:begin
            if(cnt_out == length ) n_state = IDLE;
            else n_state = OUTPUT5;
        end
        default:begin
            n_state = IDLE;
        end
    endcase

end
//cnt input and sort
reg mode_reg;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) mode_reg <= 0;
    else if(c_state == IDLE && in_valid)   mode_reg <= out_mode;
    else mode_reg <= mode_reg;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        cnt_in <= 7;
    end
    else if(n_state == INPUT)begin
        cnt_in <= cnt_in - 1;
    end
    else begin
        cnt_in <= 7;
    end
end
//cnt encode

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_encode <= 0;
    else if(n_state == ENCODE) cnt_encode <= cnt_encode + 1 ;
    else cnt_encode <= 0 ;
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1)begin
            weight[i] <= 31;
            addr[i] <= 15;
        end
    end
    else begin
        for(i=0;i<8;i=i+1)begin
            weight[i]  <= n_weight[i];
            addr[i]  <= n_addr[i];
        end
    
    end
end

//insertion sort during half cycle input
wire [3:0] in_sort_addr;
wire [4:0] in_sort_weight;

wire[27:0] in_addr_seq;
wire [34:0] in_weight_seq;

wire [31:0] out_addr_sort_1,out_addr_sort_2;
wire [39:0] out_weight_sort_1,out_weight_sort_2;

assign in_sort_addr =    addr[0];
assign in_sort_weight =  weight[0];
assign in_addr_seq =   {addr[7],addr[6],addr[5],addr[4],addr[3],addr[2],addr[1]};
assign in_weight_seq = {weight[7],weight[6],weight[5],weight[4],weight[3],weight[2],weight[1]};


eight_insertion_sort u_sort_1 (.addr(in_sort_addr),.weight(in_sort_weight),.addr_seq(in_addr_seq),.weight_seq(in_weight_seq),.out_addr(out_addr_sort_1),.out_weight(out_weight_sort_1));



always@(*)begin
    if(n_state == INPUT )begin
        n_addr[0] = cnt_in;
        n_addr[1] = out_addr_sort_1[3:0];
        n_addr[2] = out_addr_sort_1[7:4];
        n_addr[3] = out_addr_sort_1[11:8];
        n_addr[4] = out_addr_sort_1[15:12];
        n_addr[5] = out_addr_sort_1[19:16];
        n_addr[6] = out_addr_sort_1[23:20];
        n_addr[7] = out_addr_sort_1[27:24];

        n_weight[0] = in_weight;
        n_weight[1] = out_weight_sort_1[4:0];
        n_weight[2] = out_weight_sort_1[9:5];
        n_weight[3] = out_weight_sort_1[14:10];
        n_weight[4] = out_weight_sort_1[19:15];
        n_weight[5] = out_weight_sort_1[24:20];
        n_weight[6] = out_weight_sort_1[29:25];
        n_weight[7] = out_weight_sort_1[34:30];
    end
    else if(n_state == ENCODE)begin
        for(i=0;i<8;i=i+1)begin
            n_weight[i] = weight_encode_2[i];
            n_addr[i]  = addr_encode_2[i];
        end
    end
    else begin
        for(i=0;i<8;i=i+1)begin
            n_weight[i] = 31;
            n_addr[i] = 15;
        end
    end 
end
//stage 1 encode
wire [4:0] new_weight_1,new_weight_2;
assign new_weight_1 = out_weight_sort_1[4:0] + out_weight_sort_1[9:5];
always@(*)begin
    if(cnt_encode == 0) begin
        addr_encode_1[7] = 15;
        addr_encode_1[6] = out_addr_sort_1[31:28];  //1st encode
        addr_encode_1[5] = out_addr_sort_1[27:24];
        addr_encode_1[4] = out_addr_sort_1[23:20];
        addr_encode_1[3] = out_addr_sort_1[19:16];
        addr_encode_1[2] = out_addr_sort_1[15:12];
        addr_encode_1[1] = out_addr_sort_1[11:8];
        addr_encode_1[0] = 8;

        
        weight_encode_1[7] = 31;              
        weight_encode_1[6] = out_weight_sort_1[39:35];
        weight_encode_1[5] = out_weight_sort_1[34:30];
        weight_encode_1[4] = out_weight_sort_1[29:25];
        weight_encode_1[3] = out_weight_sort_1[24:20];
        weight_encode_1[2] = out_weight_sort_1[19:15];
        weight_encode_1[1] = out_weight_sort_1[14:10];
        weight_encode_1[0] = new_weight_1;
        weight_encode_1[7] = 31;       
    end
    else if(cnt_encode == 1) begin                 //3rd encode
        addr_encode_1[7] = 15;
        addr_encode_1[6] = 15;
        addr_encode_1[5] = 15;
        addr_encode_1[4] = out_addr_sort_1[23:20];
        addr_encode_1[3] = out_addr_sort_1[19:16];
        addr_encode_1[2] = out_addr_sort_1[15:12];
        addr_encode_1[1] = out_addr_sort_1[11:8];
        addr_encode_1[0] = 10;

        weight_encode_1[7] = 31;     
        weight_encode_1[6] = 31;
        weight_encode_1[5] = 31;
        weight_encode_1[4] = out_weight_sort_1[29:25];
        weight_encode_1[3] = out_weight_sort_1[24:20];
        weight_encode_1[2] = out_weight_sort_1[19:15];
        weight_encode_1[1] = out_weight_sort_1[14:10];
        weight_encode_1[0] = new_weight_1;
    end
    else begin                                 //5th encode
        addr_encode_1[7] = 15;
        addr_encode_1[6] = 15;
        addr_encode_1[5] = 15;
        addr_encode_1[4] = 15;
        addr_encode_1[3] = 15;
        addr_encode_1[2] = out_addr_sort_1[15:12];
        addr_encode_1[1] = out_addr_sort_1[11:8];
        addr_encode_1[0] = 12;
        
        weight_encode_1[7] = 31;       
        weight_encode_1[6] = 31;
        weight_encode_1[5] = 31;
        weight_encode_1[4] = 31;
        weight_encode_1[3] = 31;
        weight_encode_1[2] = out_weight_sort_1[19:15];
        weight_encode_1[1] = out_weight_sort_1[14:10];
        weight_encode_1[0] = new_weight_1;

    end

end



//encode 2 stage

eight_insertion_sort u_sort_2 (.addr(addr_encode_1[0]),.weight(weight_encode_1[0])
        ,.addr_seq({addr_encode_1[7],addr_encode_1[6],addr_encode_1[5],addr_encode_1[4],addr_encode_1[3],addr_encode_1[2],addr_encode_1[1]})
        ,.weight_seq({weight_encode_1[7],weight_encode_1[6],weight_encode_1[5],weight_encode_1[4],weight_encode_1[3],weight_encode_1[2],weight_encode_1[1]})
        ,.out_addr(out_addr_sort_2),.out_weight(out_weight_sort_2));



//plus 

assign new_weight_2 = out_weight_sort_2[4:0] + out_weight_sort_2[9:5];
always@(*)begin
    if(cnt_encode==0) begin              //2nd encode;  
        addr_encode_2[7] = 15;
        addr_encode_2[6] = 15;
        addr_encode_2[5] = out_addr_sort_2[27:24];     
        addr_encode_2[4] = out_addr_sort_2[23:20];
        addr_encode_2[3] = out_addr_sort_2[19:16];
        addr_encode_2[2] = out_addr_sort_2[15:12];
        addr_encode_2[1] = out_addr_sort_2[11:8];
        addr_encode_2[0] = 9;  

        weight_encode_2[7] = 31;
        weight_encode_2[6] = 31;   
        weight_encode_2[5] = out_weight_sort_2[34:30];
        weight_encode_2[4] = out_weight_sort_2[29:25];
        weight_encode_2[3] = out_weight_sort_2[24:20];
        weight_encode_2[2] = out_weight_sort_2[19:15];
        weight_encode_2[1] = out_weight_sort_2[14:10];
        weight_encode_2[0] = new_weight_2;
    end
    else if(cnt_encode==1)begin         //4th encode
        addr_encode_2[7] = 15;  
        addr_encode_2[6] = 15;
        addr_encode_2[5] = 15;
        addr_encode_2[4] = 15;
        addr_encode_2[3] = out_addr_sort_2[19:16];
        addr_encode_2[2] = out_addr_sort_2[15:12];
        addr_encode_2[1] = out_addr_sort_2[11:8];
        addr_encode_2[0] = 11;

        weight_encode_2[7] = 31;
        weight_encode_2[6] = 31;
        weight_encode_2[5] = 31;
        weight_encode_2[4] = 31;
        weight_encode_2[3] = out_weight_sort_2[24:20];
        weight_encode_2[2] = out_weight_sort_2[19:15];
        weight_encode_2[1] = out_weight_sort_2[14:10];
        weight_encode_2[0] = new_weight_2;
    end
    else begin                           //6th encode
        addr_encode_2[7] = 15;  
        addr_encode_2[6] = 15;
        addr_encode_2[5] = 15;
        addr_encode_2[4] = 15;
        addr_encode_2[3] = 15;
        addr_encode_2[2] = 15;
        addr_encode_2[1] = out_addr_sort_2[11:8];
        addr_encode_2[0] = 13;

        weight_encode_2[7] = 31;
        weight_encode_2[6] = 31;
        weight_encode_2[5] = 31;
        weight_encode_2[4] = 31;
        weight_encode_2[3] = 31;
        weight_encode_2[2] = 31;
        weight_encode_2[1] = out_weight_sort_2[14:10];
        weight_encode_2[0] = new_weight_2;
    end

end

//sort IP for 7nd encode
wire [7:0] ip_out;
SORT_IP #(.IP_WIDTH(2))  I_SORT_IP(.IN_character({addr[1],addr[0]}), .IN_weight({weight[1],weight[0]}), .OUT_character(ip_out)); 





//encode
reg [7:0] encoder_table[0:13];
reg [7:0] encoder_table_reg[8:13];
wire [7:0] encoder_exist_list_1,encoder_exist_list_2;
assign encoder_exist_list_1 = encoder_table[out_addr_sort_1[7:4]] | encoder_table[out_addr_sort_1[3:0]] ;
assign encoder_exist_list_2 = encoder_table[out_addr_sort_2[7:4]] | encoder_table[out_addr_sort_2[3:0]] ;

always@(*) begin
    encoder_table[0] = 8'b00000001;
    encoder_table[1] = 8'b00000010;
    encoder_table[2] = 8'b00000100;
    encoder_table[3] = 8'b00001000;
    encoder_table[4] = 8'b00010000;
    encoder_table[5] = 8'b00100000;
    encoder_table[6] = 8'b01000000;
    encoder_table[7] = 8'b10000000;
    encoder_table[8] = (cnt_encode==0)? encoder_exist_list_1 : encoder_table_reg[8];
    encoder_table[9] = (cnt_encode==0)? encoder_exist_list_2 : encoder_table_reg[9];
    encoder_table[10]= (cnt_encode==1)? encoder_exist_list_1 : encoder_table_reg[10];
    encoder_table[11]= (cnt_encode==1)? encoder_exist_list_2 : encoder_table_reg[11];
    encoder_table[12]= (cnt_encode==2)? encoder_exist_list_1 : encoder_table_reg[12];
    encoder_table[13]= (cnt_encode==2)? encoder_exist_list_2 : encoder_table_reg[13];
end

always@(posedge clk )begin
    if(cnt_encode ==0) begin
        encoder_table_reg[8] <= encoder_table[8];
        encoder_table_reg[9] <= encoder_table[9];
    end
    else begin
        encoder_table_reg[8] <= encoder_table_reg[8];
        encoder_table_reg[9] <= encoder_table_reg[9];
    end

    if(cnt_encode == 1)begin
        encoder_table_reg[10] <= encoder_table[10];
        encoder_table_reg[11] <= encoder_table[11];
    end
    else begin
        encoder_table_reg[10] <= encoder_table_reg[10];
        encoder_table_reg[11] <= encoder_table_reg[11];
    end

    if(cnt_encode == 2)begin
        encoder_table_reg[12] <= encoder_table[12];
        encoder_table_reg[13] <= encoder_table[13];
    end
    else begin
        encoder_table_reg[12] <= encoder_table_reg[12];
        encoder_table_reg[13] <= encoder_table_reg[13];
    end
end
// enocoding length&code
reg [6:0] nn_huffcode[0:7];
reg [2:0] nn_hufflength[0:7];
reg [6:0] n_huffcode[0:7];
reg [2:0] n_hufflength[0:7];
reg [6:0] huffcode[0:7];
reg [2:0] hufflength[0:7];
reg [7:0] exist_array1;
reg [7:0] exist_array2;
reg [7:0] right_1_one;
reg [7:0] left_1_zero;
reg [7:0] right_2_one;
reg [7:0] left_2_zero;

always@(posedge clk )begin
    if( n_state == ENCODE)begin
            for(i=0;i<8;i=i+1) begin
                if(encoder_exist_list_1[i] & encoder_exist_list_2[i]) hufflength[i] <= hufflength[i] + 2;
                else if(encoder_exist_list_1[i] | encoder_exist_list_2[i]) hufflength[i] <= hufflength[i] + 1;
                else hufflength[i] <= hufflength[i];
                end
            end 
    else if(c_state == IDLE)begin
        for(i=0;i<8;i=i+1)begin
            hufflength[i] <= 0;
        end
    end   
    else begin
        for(i=0;i<8;i=i+1)begin
            hufflength[i] <= n_hufflength[i];
        end
    end
end

always@(posedge clk )begin
    if( n_state == ENCODE)begin
            for(i=0;i<8;i=i+1) begin
                if(left_1_zero[i]  & left_2_zero[i])  huffcode[i] <= {huffcode[i][4:0],2'b00};
                else if(left_1_zero[i] &  right_2_one[i])  huffcode[i] <= {huffcode[i][4:0],2'b01};
                else if(right_1_one[i] & left_2_zero[i])  huffcode[i] <= {huffcode[i][4:0],2'b10};
                else if(right_1_one[i] & right_2_one[i])  huffcode[i] <= {huffcode[i][4:0],2'b11};
                else if(right_1_one[i] | right_2_one[i])  huffcode[i] <= {huffcode[i][5:0],1'b1};
                else if(left_1_zero[i] | left_2_zero[i])  huffcode[i] <= {huffcode[i][5:0],1'b0};
                else huffcode[i] <= huffcode[i];
            end
     end 
    else begin
        for(i=0;i<8;i=i+1)begin
            huffcode[i] <= n_huffcode[i];
        end
    end
end


always@(*)begin
    left_1_zero = encoder_table[out_addr_sort_1[7:4]];
    right_1_one = encoder_table[out_addr_sort_1[3:0]];
    left_2_zero = encoder_table[out_addr_sort_2[7:4]];
    right_2_one = encoder_table[out_addr_sort_2[3:0]];
end

//preoutput
always@(*)begin
    for(i=0;i<8;i=i+1)begin
            if(cnt_encode==3)begin
                if(encoder_table[ip_out[7:4]][i])begin
                    n_huffcode[i] =  {huffcode[i][5:0],1'b0};
                end
                else begin
                    n_huffcode[i] =  {huffcode[i][5:0],1'b1};
                end
            end
            else begin
                n_huffcode[i] = huffcode[i];
            end
    end
end

always@(*)begin
    for(i=0;i<8;i=i+1)begin
        n_hufflength[i] = hufflength[i];
    end
end

//
reg [6:0] huffman_output;
always@(*)begin
    if(n_state == OUTPUT1 || (c_state == OUTPUT1 && n_hufflength[3]!=0) ) begin
        huffman_output = n_huffcode[3];
    end
    else if(c_state == OUTPUT2 || n_state == OUTPUT2) begin
        huffman_output = (mode_reg)? n_huffcode[5]:n_huffcode[2];
    end
    else if(c_state == OUTPUT3) begin
        huffman_output = (mode_reg)?n_huffcode[2]:n_huffcode[1];
    end
    else if(c_state == OUTPUT4) begin
        huffman_output = (mode_reg)?n_huffcode[7]:n_huffcode[0];
    end
    else if(c_state == OUTPUT5) begin
        huffman_output =(mode_reg)? n_huffcode[6]:n_huffcode[4];
    end
    else begin
        huffman_output = 0;
    end
end

always@(*)begin
    if( ((c_state == OUTPUT1 && n_hufflength[3]!=0) )  || n_state == OUTPUT1) begin
        length = n_hufflength[3];
    end
    else if(c_state == OUTPUT2 ) begin
        length = (mode_reg)? n_hufflength[5]:n_hufflength[2];
    end
    else if(c_state == OUTPUT3) begin
        length = (mode_reg)?n_hufflength[2]:n_hufflength[1];
    end
    else if(c_state == OUTPUT4) begin
        length =(mode_reg)? n_hufflength[7]:n_hufflength[0];
    end
    else if(c_state == OUTPUT5) begin
        length = (mode_reg)? n_hufflength[6]:n_hufflength[4];
    end
    else begin
        length = 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_out <=0;
    else if(n_hufflength[3]==0 && c_state == OUTPUT1) cnt_out <= 1;
    else if(cnt_out == length)  cnt_out <= 0;
    else if(n_state==OUTPUT1 || n_state == OUTPUT2 || n_state == OUTPUT3 || n_state == OUTPUT4 || n_state == OUTPUT5) cnt_out <= cnt_out + 1;
    else cnt_out <= 0;
end
///


always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        out_valid <= 0;
        out_code <= 0;
    end
    else if(n_state==OUTPUT1 || n_state == OUTPUT2 || n_state == OUTPUT3 || n_state == OUTPUT4 || n_state == OUTPUT5 || c_state == OUTPUT5) begin
        out_valid <= 1;
        out_code <=huffman_output[cnt_out];
    end
    else begin
        out_valid <= 0;
        out_code <= 0;
    end
end


endmodule




module eight_insertion_sort(addr,weight,addr_seq,weight_seq,out_addr,out_weight);
    input wire [3:0] addr;
    input wire [27:0] addr_seq;
    output reg [31:0] out_addr;

    input wire [4:0] weight;
    input wire [34:0] weight_seq;
    output reg [39:0] out_weight;

    wire [3:0] addr_array[0:7];
    wire [4:0] weight_array[0:7];

    assign addr_array[0] = addr_seq[3:0];
    assign addr_array[1] = addr_seq[7:4];
    assign addr_array[2] = addr_seq[11:8];
    assign addr_array[3] = addr_seq[15:12];
    assign addr_array[4] = addr_seq[19:16];
    assign addr_array[5] = addr_seq[23:20];
    assign addr_array[6] = addr_seq[27:24];

    assign weight_array[0] = weight_seq[4:0];
    assign weight_array[1] = weight_seq[9:5];
    assign weight_array[2] = weight_seq[14:10];
    assign weight_array[3] = weight_seq[19:15];
    assign weight_array[4] = weight_seq[24:20];
    assign weight_array[5] = weight_seq[29:25];
    assign weight_array[6] = weight_seq[34:30];

    always@(*)begin
        if(weight > weight_array[3])begin
            if(weight > weight_array[5])begin
                if(weight > weight_array[6])begin
                    out_weight = {weight,weight_array[6],weight_array[5],weight_array[4],weight_array[3],weight_array[2],weight_array[1],weight_array[0]};
                    out_addr = {addr,addr_array[6],addr_array[5],addr_array[4],addr_array[3],addr_array[2],addr_array[1],addr_array[0]};
                end
                else begin
                    out_weight = {weight_array[6],weight,weight_array[5],weight_array[4],weight_array[3],weight_array[2],weight_array[1],weight_array[0]};
                    out_addr = {addr_array[6],addr,addr_array[5],addr_array[4],addr_array[3],addr_array[2],addr_array[1],addr_array[0]};
                end
            end
            else begin
                if(weight > weight_array[4])begin
                    out_weight = {weight_array[6],weight_array[5],weight,weight_array[4],weight_array[3],weight_array[2],weight_array[1],weight_array[0]};
                    out_addr = {addr_array[6],addr_array[5],addr,addr_array[4],addr_array[3],addr_array[2],addr_array[1],addr_array[0]};
                end
                else begin
                    out_weight = {weight_array[6],weight_array[5],weight_array[4],weight,weight_array[3],weight_array[2],weight_array[1],weight_array[0]};
                    out_addr = {addr_array[6],addr_array[5],addr_array[4],addr,addr_array[3],addr_array[2],addr_array[1],addr_array[0]};
                end
            end
        end

        else begin
            if(weight > weight_array[1])begin
                if(weight > weight_array[2])begin
                    out_weight = {weight_array[6],weight_array[5],weight_array[4],weight_array[3],weight,weight_array[2],weight_array[1],weight_array[0]};
                    out_addr = {addr_array[6],addr_array[5],addr_array[4],addr_array[3],addr,addr_array[2],addr_array[1],addr_array[0]};
                end
                else begin
                    out_weight = {weight_array[6],weight_array[5],weight_array[4],weight_array[3],weight_array[2],weight,weight_array[1],weight_array[0]};
                    out_addr = {addr_array[6],addr_array[5],addr_array[4],addr_array[3],addr_array[2],addr,addr_array[1],addr_array[0]};
                end
            end
            else begin
                if(weight > weight_array[0])begin
                    out_weight = {weight_array[6],weight_array[5],weight_array[4],weight_array[3],weight_array[2],weight_array[1],weight,weight_array[0]};
                    out_addr = {addr_array[6],addr_array[5],addr_array[4],addr_array[3],addr_array[2],addr_array[1],addr,addr_array[0]};
                end
                else begin
                    out_weight = {weight_array[6],weight_array[5],weight_array[4],weight_array[3],weight_array[2],weight_array[1],weight_array[0],weight};
                    out_addr = {addr_array[6],addr_array[5],addr_array[4],addr_array[3],addr_array[2],addr_array[1],addr_array[0],addr};
                end
            end
        end
    end
endmodule