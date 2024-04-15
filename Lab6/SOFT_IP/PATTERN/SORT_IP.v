//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character; // index table: {4'd7,4'd6,4'd5,4'd4,4'd3,4'd2,4'd1,4'd0}
input [IP_WIDTH*5-1:0]  IN_weight;   //  value table: {5'd3,5'd7,5'd6,5'd5,5'd3,5'd3,5'd5,5'd7}

output reg [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================

// (1,2) (3,4) (5,6) (7,8)
//merge sort
//4     compare 5 times  (2+1+2=5)
//5     2+2+2+2+1 = 9    (2+2+2+2+2)
//6     3+2+2+  +5 = 12    3+2+3+2+3+2 = 15
//8     4+                   4+3+4+3+4 +3+4+3= 28   
reg [3:0] addr_in [0:7];
wire [3:0] addr[0:7][1:8];
reg [4:0] value_in[0:7];
wire [4:0] value[0:7][1:8];
//load input
genvar i;
generate
    for(i =0 ;i<8;i=i+1) begin
        always@(*)begin
            if(i>IP_WIDTH-1) begin
                addr_in[i] = 15;
                value_in[i] = 31;
            end
            else begin
                addr_in[i] = IN_character[i*4 + 3:i*4];
                value_in[i] = IN_weight[i*5 + 4:i*5];
            end
        end
    end
endgenerate

//merge sort
genvar r1;
generate
    for(r1=0;r1<8;r1=r1+2)begin
    compare c1(.in_v1(value_in[r1+1]),.in_v2(value_in[r1]),.in_a1(addr_in[r1+1]),.in_a2(addr_in[r1]),.v_big(value[r1+1][1]),.v_small(value[r1][1]),.a_big(addr[r1+1][1]),.a_small(addr[r1][1]));
    compare c3(.in_v1(value[r1+1][2]),.in_v2(value[r1][2]),.in_a1(addr[r1+1][2]),.in_a2(addr[r1][2]),.v_big(value[r1+1][3]),.v_small(value[r1][3]),.a_big(addr[r1+1][3]),.a_small(addr[r1][3]));
    compare c5(.in_v1(value[r1+1][4]),.in_v2(value[r1][4]),.in_a1(addr[r1+1][4]),.in_a2(addr[r1][4]),.v_big(value[r1+1][5]),.v_small(value[r1][5]),.a_big(addr[r1+1][5]),.a_small(addr[r1][5]));
    compare c7(.in_v1(value[r1+1][6]),.in_v2(value[r1][6]),.in_a1(addr[r1+1][6]),.in_a2(addr[r1][6]),.v_big(value[r1+1][7]),.v_small(value[r1][7]),.a_big(addr[r1+1][7]),.a_small(addr[r1][7]));
end
endgenerate

genvar r2;
generate
    for(r2=1;r2<6;r2=r2+2) begin
        compare c2(.in_v1(value[r2+1][1]),.in_v2(value[r2][1]),.in_a1(addr[r2+1][1]),.in_a2(addr[r2][1]),.v_big(value[r2+1][2]),.v_small(value[r2][2]),.a_big(addr[r2+1][2]),.a_small(addr[r2][2]));
        compare c4(.in_v1(value[r2+1][3]),.in_v2(value[r2][3]),.in_a1(addr[r2+1][3]),.in_a2(addr[r2][3]),.v_big(value[r2+1][4]),.v_small(value[r2][4]),.a_big(addr[r2+1][4]),.a_small(addr[r2][4]));
        compare c6(.in_v1(value[r2+1][5]),.in_v2(value[r2][5]),.in_a1(addr[r2+1][5]),.in_a2(addr[r2][5]),.v_big(value[r2+1][6]),.v_small(value[r2][6]),.a_big(addr[r2+1][6]),.a_small(addr[r2][6]));
        compare c8(.in_v1(value[r2+1][7]),.in_v2(value[r2][7]),.in_a1(addr[r2+1][7]),.in_a2(addr[r2][7]),.v_big(value[r2+1][8]),.v_small(value[r2][8]),.a_big(addr[r2+1][8]),.a_small(addr[r2][8]));
    end
endgenerate

assign value[0][2] = value[0][1];
assign value[7][2] = value[7][1];
assign value[0][4] = value[0][3];
assign value[7][4] = value[7][3];
assign value[0][6] = value[0][5];
assign value[7][6] = value[7][5];
assign value[0][8] = value[0][7];
assign value[7][8] = value[7][7];
assign addr[0][2] = addr[0][1];
assign addr[7][2] = addr[7][1];
assign addr[0][4] = addr[0][3];
assign addr[7][4] = addr[7][3];
assign addr[0][6] = addr[0][5];
assign addr[7][6] = addr[7][5];
assign addr[0][8] = addr[0][7];
assign addr[7][8] = addr[7][7];

    
always@(*)begin
    case(IP_WIDTH)
	    3'd2: OUT_character = {addr[1][1],addr[0][1]};
        3'd3: OUT_character = {addr[2][3],addr[1][3],addr[0][3]};
        3'd4: OUT_character = {addr[3][4],addr[2][4],addr[1][4],addr[0][4]};
        3'd5: OUT_character = {addr[4][5],addr[3][5],addr[2][5],addr[1][5],addr[0][5]};
        3'd6: OUT_character = {addr[5][6],addr[4][6],addr[3][6],addr[2][6],addr[1][6],addr[0][6]};
        3'd7: OUT_character = {addr[6][7],addr[5][7],addr[4][7],addr[3][7],addr[2][7],addr[1][7],addr[0][7]};
        default: OUT_character = {addr[7][8],addr[6][8],addr[5][8],addr[4][8],addr[3][8],addr[2][8],addr[1][8],addr[0][8]};
    endcase
end



endmodule


module compare(in_v1,in_v2,in_a1,in_a2,v_big,v_small,a_big,a_small);
    input [4:0] in_v1,in_v2;
    input [3:0] in_a1,in_a2;
    output reg [4:0] v_big,v_small;
    output reg [3:0] a_big,a_small;

    always@(*)begin
        if(in_v1 < in_v2)begin
            v_big = in_v2;
            v_small = in_v1;
            a_big = in_a2;
            a_small = in_a1;
        end
        else begin
            v_big = in_v1;
            v_small = in_v2;
            a_big = in_a1;
            a_small = in_a2;
        end
    end
endmodule