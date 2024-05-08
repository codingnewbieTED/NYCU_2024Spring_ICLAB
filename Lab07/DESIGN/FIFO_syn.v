//================================================================
//  Reference: https://aijishu.com/a/1060000000146410  by: Old Lee (sin)
//  winc = ! wfull    ;    rinc = ! rempty                               
//================================================================
module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output reg flag_fifo_to_clk1;
input flag_clk1_to_fifo;
//================================================================
//  wire
//================================================================
wire [WIDTH-1:0] rdata_q;
//wire [WIDTH-1:0] wdata_q; //for debug
wire wen;
//
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;
wire[$clog2(WORDS):0] wq2_rptr,rq2_wptr;
reg [$clog2(WORDS):0] addr_A,addr_B;
wire [$clog2(WORDS):0] n_addr_A,n_addr_B;
wire [$clog2(WORDS):0] n_rptr,n_wptr;
/*
reg wpush;
always@(posedge wclk or negedge rst_n)begin
    if(!rst_n) wpush <= 0;
    else if(winc) wpush <= 1;
    else if(!wen) wpush <= 0; 
end*/
//================================================================
//  FIFO addr && gray code                  
//================================================================
assign n_addr_A = addr_A + 1;
assign n_addr_B = addr_B + 1;
assign n_wptr = (addr_A >> 1) ^ addr_A;  //(n_addr_A >> 1) ^ n_addr_A;
assign n_rptr = (addr_B >> 1) ^ addr_B;  //(n_addr_B >> 1) ^ n_addr_B;

always@(posedge wclk or negedge rst_n) begin
    if(!rst_n) addr_A <= 7'd0;
    else if(winc ) addr_A <= n_addr_A;
    else addr_A <= addr_A;
end

always@(posedge rclk or negedge rst_n) begin
    if(!rst_n) addr_B <= 7'd0;
    else if(rinc) addr_B <= n_addr_B;
    else addr_B <= addr_B;
end
//graycode:
always@(*)begin
    wptr = n_wptr;
    rptr = n_rptr;
end
/*
always@(posedge wclk or negedge rst_n)begin
    if(!rst_n) begin
        wptr <= 0;
    end
    else if(winc )begin
        wptr <= n_wptr;
    end

end

always@(posedge rclk or negedge rst_n)begin
    if(!rst_n) begin
        rptr <= 0;
    end
    else if(rinc) begin
        rptr <= n_rptr;
    end
end*/
//================================================================
//  WFULL && REMPTY                 
//================================================================
always@(*) begin
    if(wptr[6:5] == ~wq2_rptr[6:5] && wptr[4:0] == wq2_rptr[4:0]) wfull = 1;
    else wfull = 0;
end

always@(*) begin
     if(rptr == rq2_wptr) rempty = 1;
    else     rempty = 0;
end
//enable
assign wen = !winc;  //wfull;
//================================================================
//  DATA OUTPUT && valid               
//================================================================
reg flag;
always@(posedge rclk or negedge rst_n)begin
    if(!rst_n)  flag<=0;
    else flag <= rinc;
end
//out_valid
always@(posedge rclk or negedge rst_n)begin
    if(!rst_n)  flag_fifo_to_clk1<=0;
    else  flag_fifo_to_clk1<=flag;
end

//  Add one more register stage to rdata
always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else if(flag) begin
			rdata <= rdata_q;
		end
    else rdata <= 0;
end


//================================================================
//  Other module : synchornizer && Dual port RAM             
//================================================================
NDFF_BUS_syn #(7) r2w(
    .D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n)
);
NDFF_BUS_syn #(7) w2r(
    .D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n)
);


DUAL_64X8X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wen),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(addr_A[0]),  
    .A1(addr_A[1]),
    .A2(addr_A[2]),
    .A3(addr_A[3]),
    .A4(addr_A[4]),
    .A5(addr_A[5]),
    .B0(addr_B[0]),
    .B1(addr_B[1]),
    .B2(addr_B[2]),
    .B3(addr_B[3]),
    .B4(addr_B[4]),
    .B5(addr_B[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    /*
    .DOA0(wdata_q[0]),
    .DOA1(wdata_q[1]),
    .DOA2(wdata_q[2]),
    .DOA3(wdata_q[3]),
    .DOA4(wdata_q[4]),
    .DOA5(wdata_q[5]),
    .DOA6(wdata_q[6]),
    .DOA7(wdata_q[7]),  //for debug */
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7])
);


endmodule

