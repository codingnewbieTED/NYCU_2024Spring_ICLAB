//================================================================
//  HANDSHAKE SYNCHRONIZER
//  Reference: https://www.semanticscholar.org/paper/Clock-domain-crossing-formal-verification%3A-a-Kebaili-Brignone/8ca30b582acf47b79fb5588a05e6da10449bf237/figure/0
//  Here use xor to realize
//================================================================

module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;


//data path


always@(*)begin
     if( dreq^dack)begin 
        dvalid = 1;
        dout = din;
    end
    else begin
        dvalid = 0;
        dout = 0;
    end
end
//control signal
//sreq
always@(*)begin
         sreq = sready;
end
//dreq
NDFF_syn req_s2d(
    .D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n)
);
//dack
always@(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dack <= 0;
    end
    else 
        dack <= dreq;
end
//sack
NDFF_syn  ack_d2s(
    .D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n)
);

assign sidle = (sack == sreq) ? 1 : 0;

endmodule

/*
reg [7:0] data_in_clk1;
always@(posedge sclk or negedge rst_n)begin
    if(!rst_n) data_in_clk1 <= 0;
    else if(sready^sreq)    data_in_clk1 <= din;
    else data_in_clk1 <= data_in_clk1;
end */
//output
/*
always@(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dvalid <= 0;
        dout <= 0;
    end
    else if( dreq^dack)begin 
        dvalid <= 1;
        dout <= din;
    end
    else begin
        dvalid <= 0;
        dout <= 0;
    end
end*/

/*
always@(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        sreq <= 0;
    end
    else if(sready^sreq)
        sreq <= sready;
    else sreq <= sreq;
end*/
