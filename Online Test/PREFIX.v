module PREFIX (
    // input port
    clk,
    rst_n,
    in_valid,
    opt,
    in_data,
    // output port
    out_valid,
    out
);

input clk;
input rst_n;
input in_valid;
input opt;
input [4:0] in_data;
output reg out_valid;
output reg signed [94:0] out;
//wire
integer i;
reg [3:0] c_state,n_state;
parameter IDLE = 'd0, PREFIX = 'd1,find_operator = 'd2, CAL = 'd3,OUTPUT = 'd4;
parameter INFIX = 'd5,STACK = 'd6,scan_string = 'd7,STACK_OP = 'd8;
reg [4:0] position;
reg [4:0] cnt_opt;
reg [3:0] stack_depth;
reg [4:0] stack_2[1:9];
reg signed [4:0] array[1:19];
reg  signed [25:0] stack [1:9];
reg signed [40:0] stack_top;  //fuck , 95 bit output?????(only for opt 1) ,make u can't synthesis part1 QQ
reg signed [40:0] n_stack;
reg [4:0] RPE [1:19];
//fsm
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  c_state <= IDLE;
    else c_state <= n_state;
end

always@(*)begin
    case(c_state)
    IDLE :begin
        if(in_valid) begin
            if(opt == 0) n_state = PREFIX;
            else n_state = INFIX;
        end
        else n_state = IDLE;
    end
    PREFIX: begin
        if(!in_valid) n_state = find_operator;
        else n_state = PREFIX;
    end
    find_operator:begin
        if(cnt_opt == 9) n_state = OUTPUT;
        else n_state = STACK;
    end
    STACK:begin
        n_state = CAL;
    end
    CAL: n_state = find_operator;
    INFIX:begin
        if(!in_valid) n_state = scan_string;
        else n_state = INFIX;
    end
    scan_string:begin
        if(cnt_opt == 19) n_state = OUTPUT;
        else if(array[19][4]==0) n_state = scan_string;
        else if(array[19][4] && stack_depth == 0) n_state = scan_string;
        else n_state = STACK_OP;
    end
    STACK_OP:begin
        if(stack_depth != 0 && array[19][1] < stack_2[9][1] ) n_state = STACK_OP;
        else n_state = scan_string;
    end
    OUTPUT : begin
        n_state = IDLE;
    end
    default: n_state =IDLE;
    endcase
end

//control
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_opt <= 0;
    else if(c_state == CAL) cnt_opt <= cnt_opt +1;
    else if(c_state == scan_string) cnt_opt <= cnt_opt +1;
    else if(c_state == IDLE) cnt_opt <= 0;
    else cnt_opt <= cnt_opt;
end
//depth
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) stack_depth <= 0;
    else if(c_state == IDLE) stack_depth <= 0;
    else if(array[19][4] && stack_depth == 0 && c_state == scan_string) stack_depth <= 1;
    else if(c_state == STACK_OP && n_state == STACK_OP) stack_depth <= stack_depth - 1;
    else if(c_state == STACK_OP && n_state == scan_string) stack_depth <= stack_depth + 1;
end
//stack_2
always@(posedge clk)begin
    if( (array[19][4] && stack_depth == 0 && c_state == scan_string) || (c_state == STACK_OP && n_state == scan_string))begin
        stack_2[9] <= array[19];
        for(i=1;i<9;i=i+1) stack_2[i] <= stack_2[i+1];
    end
    else if(c_state == STACK_OP && n_state == STACK_OP)begin
        for(i=1;i<10;i=i+1) stack_2[i] <= stack_2[i-1];
    end
end
//RPE
always@(posedge clk)begin
    if(c_state == scan_string && n_state == scan_string && !array[19][4] )begin
        RPE[19] <= array[19];
        for(i=1;i<19;i=i+1) RPE[i] <= RPE[i+1];
    end
    else if(c_state == STACK_OP && n_state == STACK_OP)begin
        RPE[19] <= stack_2[9];
        for(i=1;i<19;i=i+1) RPE[i] <= RPE[i+1];
    end
    else if(c_state == scan_string && n_state == OUTPUT)begin
        if(stack_depth==9) begin
            for(i=1;i<11;i=i+1) RPE[i] <= RPE[i+9];
            RPE[19] <= stack_2[1];
            RPE[18] <= stack_2[2];
            RPE[17] <= stack_2[3];
            RPE[16] <= stack_2[4];
            RPE[15] <= stack_2[5];
            RPE[14] <= stack_2[6];
            RPE[13] <= stack_2[7];
            RPE[12] <= stack_2[8];
            RPE[11] <= stack_2[9];
        end
        else if (stack_depth == 8) begin
            for(i=1;i<12;i=i+1) RPE[i] <= RPE[i+8];
            RPE[19] <= stack_2[2];
            RPE[18] <= stack_2[3];
            RPE[17] <= stack_2[4];
            RPE[16] <= stack_2[5];
            RPE[15] <= stack_2[6];
            RPE[14] <= stack_2[7];
            RPE[13] <= stack_2[8];
            RPE[12] <= stack_2[9];
        end
        else if(stack_depth == 7)begin
            for(i=1;i<13;i=i+1) RPE[i] <= RPE[i+7];
            RPE[19] <= stack_2[3];
            RPE[18] <= stack_2[4];
            RPE[17] <= stack_2[5];
            RPE[16] <= stack_2[6];
            RPE[15] <= stack_2[7];
            RPE[14] <= stack_2[8];
            RPE[13] <= stack_2[9];
        end
        else if(stack_depth == 6)begin
            for(i=1;i<14;i=i+1) RPE[i] <= RPE[i+6];
            RPE[19] <= stack_2[4];
            RPE[18] <= stack_2[5];
            RPE[17] <= stack_2[6];
            RPE[16] <= stack_2[7];
            RPE[15] <= stack_2[8];
            RPE[14] <= stack_2[9];
        end
        else if(stack_depth == 5)begin
            for(i=1;i<15;i=i+1) RPE[i] <= RPE[i+5];
            RPE[19] <= stack_2[5];
            RPE[18] <= stack_2[6];
            RPE[17] <= stack_2[7];
            RPE[16] <= stack_2[8];
            RPE[15] <= stack_2[9];
        end
        else if(stack_depth == 4)begin
            for(i=1;i<16;i=i+1) RPE[i] <= RPE[i+4];
            RPE[19] <= stack_2[6];
            RPE[18] <= stack_2[7];
            RPE[17] <= stack_2[8];
            RPE[16] <= stack_2[9];
        end
        else if(stack_depth == 3)begin
            for(i=1;i<17;i=i+1) RPE[i] <= RPE[i+3];
            RPE[19] <= stack_2[7];
            RPE[18] <= stack_2[8];
            RPE[17] <= stack_2[9];
        end
        else if(stack_depth == 2)begin
            for(i=1;i<18;i=i+1) RPE[i] <= RPE[i+2];
            RPE[19] <= stack_2[8];
            RPE[18] <= stack_2[9];
        end
        else if(stack_depth == 1)begin
            for(i=1;i<19;i=i+1) RPE[i] <= RPE[i+1];
            RPE[19] <= stack_2[9];
        end
    end
end
//input array stack
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=1;i<20;i=i+1) array[i] <= 0;
    end
    else if(in_valid)begin
        array[19] <= in_data;
        for(i=1;i<19;i=i+1) array[i] <= array[i+1];
    end
    else if(c_state == STACK) begin
        if(position == 18)begin
            for(i=2;i<20;i=i+1) array[i] <= array[i-1];  
        end           
        else if(position == 17) begin
            for(i=3;i<20;i=i+1) array[i] <= array[i-2];  
        end
        else if(position == 16) begin
            for(i=4;i<20;i=i+1) array[i] <= array[i-3];  
        end
        else if(position == 15) begin
            for(i=5;i<20;i=i+1) array[i] <= array[i-4];  
        end
        else if(position == 14) begin
            for(i=6;i<20;i=i+1) array[i] <= array[i-5];  
        end
        else if(position == 13) begin
            for(i=7;i<20;i=i+1) array[i] <= array[i-6];  
        end
        else if(position == 12) begin
            for(i=8;i<20;i=i+1) array[i] <= array[i-7];  
        end
        else if(position == 11) begin
            for(i=9;i<20;i=i+1) array[i] <= array[i-8];  
        end
        else if(position == 10) begin
            for(i=10;i<20;i=i+1) array[i] <= array[i-9];  
        end
        else if(position == 9) begin
            for(i=11;i<20;i=i+1) array[i] <= array[i-10];  
        end
    end
    else if(c_state == CAL) begin
        for(i=1;i<20;i=i+1)  array[i] <= array[i-1];
    end
    else if((c_state == scan_string && n_state == scan_string) || (c_state == STACK_OP && n_state == scan_string)) begin
        for(i=1;i<20;i=i+1)  array[i] <= array[i-1];
    end
    
end
//opt 1 stack
always@(*)begin
    if(array[19] == 5'b10000) n_stack = stack_top + stack[9];
    else if(array[19] == 5'b10001) n_stack = stack_top - stack[9];
    else if(array[19] == 5'b10010) n_stack = stack_top * stack[9];
    else n_stack = stack_top / stack[9];
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0;i<10;i=i+1) stack[i] <= 0;
        stack_top <= 0;
    end
    else if(c_state == STACK) begin
        if(position == 18) begin
            stack_top <= array[19];
            for(i=1;i<9;i=i+1) stack[i] <= stack[i+1];
            stack[9] <= stack_top ;
        end
        else if(position == 17) begin
            stack_top <= array[18];
            stack[9] <= array[19];
            for(i=1;i<8;i=i+1) stack[i] <= stack[i+2];
            stack[8] <= stack_top ;
        end
        else if(position == 16) begin
            stack_top <= array[17];
            stack[9] <= array[18];
            stack[8] <= array[19];
            for(i=1;i<7;i=i+1) stack[i] <= stack[i+3];
            stack[7] <= stack_top ;
        end
        else if(position == 15) begin
            stack_top <= array[16];
            stack[9] <= array[17];
            stack[8] <= array[18];
            stack[7] <= array[19];
            for(i=1;i<6;i=i+1) stack[i] <= stack[i+4];
            stack[6] <= stack_top ;
        end
        else if(position == 14) begin
            stack_top <= array[15];
            stack[9] <= array[16];
            stack[8] <= array[17];
            stack[7] <= array[18];
            stack[6] <= array[19];
            for(i=1;i<5;i=i+1) stack[i] <= stack[i+5];
            stack[5] <= stack_top ;
        end
        else if(position == 13) begin
            stack_top <= array[14];
            stack[9] <= array[15];
            stack[8] <= array[16];
            stack[7] <= array[17];
            stack[6] <= array[18];
            stack[5] <= array[19];
            for(i=1;i<4;i=i+1) stack[i] <= stack[i+6];
            stack[4] <= stack_top ;
        end
        else if(position == 12) begin
            stack_top <= array[13];
            stack[9] <= array[14];
            stack[8] <= array[15];
            stack[7] <= array[16];
            stack[6] <= array[17];
            stack[5] <= array[18];
            stack[4] <= array[19];
            for(i=1;i<3;i=i+1) stack[i] <= stack[i+7];
            stack[3] <= stack_top ;
        end
        else if(position == 11) begin
            stack_top <= array[12];
            stack[9] <= array[13];
            stack[8] <= array[14];
            stack[7] <= array[15];
            stack[6] <= array[16];
            stack[5] <= array[17];
            stack[4] <= array[18];
            stack[3] <= array[19];
            stack[2] <= stack_top ;
            stack[1] <= stack[9];
        end
        else if(position == 10) begin
            stack_top <= array[11];
            stack[9] <= array[12];
            stack[8] <= array[13];
            stack[7] <= array[14];
            stack[6] <= array[15];
            stack[5] <= array[16];
            stack[4] <= array[17];
            stack[3] <= array[18];
            stack[2] <= array[19];
            stack[1] <= stack_top ;
        end
        else if(position == 9) begin
            stack_top <= array[10];
            stack[9] <= array[11];
            stack[8] <= array[12];
            stack[7] <= array[13];
            stack[6] <= array[14];
            stack[5] <= array[15];
            stack[4] <= array[16];
            stack[3] <= array[17];
            stack[2] <= array[18];
            stack[1] <= array[19];
        end
    end
    else if(c_state == CAL) begin
        stack_top <= n_stack;
        for(i=1;i<10;i=i+1) stack[i] <= stack[i - 1];
    end
end

//
reg [4:0] position_reg;
always@(posedge clk)begin
    if(array[19][4] ) position <= 19;
    else if(array[18][4] ) position <= 18;
    else if(array[17][4] ) position <= 17;
    else if(array[16][4] ) position <= 16;
    else if(array[15][4] ) position <= 15;
    else if(array[14][4] ) position <= 14;
    else if(array[13][4] ) position <= 13;
    else if(array[12][4] ) position <= 12;
    else if(array[11][4]) position <= 11;
    else if(array[10][4]) position <= 10;
    else if(array[9][4] ) position <= 9;
    else position <= 0;  
end


//

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else if(c_state == find_operator && n_state == OUTPUT)begin
        out_valid <= 1;
        out <= stack_top;
    end
    else if(c_state == OUTPUT && cnt_opt == 20) begin
        out_valid <= 1;
        out <= {RPE[1],RPE[2],RPE[3],RPE[4],RPE[5],RPE[6],RPE[7],RPE[8],RPE[9],RPE[10],RPE[11],RPE[12],RPE[13],RPE[14],RPE[15],RPE[16],RPE[17],RPE[18],RPE[19]};
    end
    else begin
        out_valid <= 0;
        out <= 0;
    end
end
endmodule