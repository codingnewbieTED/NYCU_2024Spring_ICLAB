
module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i;
parameter scale1 = 2295;
parameter scale2 = 510;
//==============================================//
//           reg & wire declaration             //
//==============================================//
//reg  flag;
reg [6:0] cnt_global;
reg [4:0] cnt;
reg [7:0] img_reg[0:11];
reg [7:0] ker_reg[0:8];
reg [7:0] weight_reg[0:3];
reg [7:0] ifm[0:8];
reg [7:0] ifm_3to0,ifm_4to1,ifm_5to2,ifm_6to3,ifm_7to4,ifm_8to5;
reg window_en[0:8];
//==============================================//
//                Gated clock                   //
//==============================================//
/*
reg clk_en_reg;
wire clk_gate_img;
wire clk_gate_ker;
wire clk_gate_weight;
wire addmult_sleep_clk[0:8];
wire clk_g1;

GATED_OR GATED_CG_U01 (.CLOCK(clk), .SLEEP_CTRL( cnt_global >= 72&& cg_en), .RST_N(rst_n), .CLOCK_GATED(clk_gate_img));
GATED_OR GATED_CG_U02 (.CLOCK(clk), .SLEEP_CTRL( cnt_global >= 9 && cg_en), .RST_N(rst_n), .CLOCK_GATED(clk_gate_ker));
GATED_OR GATED_CG_U03 (.CLOCK(clk), .SLEEP_CTRL( cnt_global >= 4 && cg_en), .RST_N(rst_n), .CLOCK_GATED(clk_gate_weight));
genvar gate_addmult;
generate
	for(gate_addmult=0;gate_addmult<9;gate_addmult=gate_addmult+1) begin
		GATED_OR GATED_CG_U0X (.CLOCK(clk), .SLEEP_CTRL( !window_en[gate_addmult]) , .RST_N(rst_n), .CLOCK_GATED(addmult_sleep_clk[gate_addmult]));
	end
endgenerate
GATED_OR GATED_CG_U04 (.CLOCK(clk), .SLEEP_CTRL( !cnt) , .RST_N(rst_n), .CLOCK_GATED(sleep_clk));*/
//GATED_OR GATED_CG_U04 (.CLOCK(clk), .SLEEP_CTRL((!((cnt >= 16 && cnt <= 32))&& cg_en ) ) , .RST_N(rst_n), .CLOCK_GATED(clk_g1));
//GATED_OR GATED_CG_U05 (.CLOCK(clk), .SLEEP_CTRL(!(cnt<38 && (cnt >=22))) , .RST_N(rst_n), .CLOCK_GATED(clk_g2));

//==============================================//
//                  design                      //
//==============================================//

//cnt_global
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) cnt_global <= 0;
	else if(out_valid) cnt_global <= 0;
	else if(in_valid || |cnt_global) cnt_global <= cnt_global + 1;    
end
//cnt
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) cnt <= 31;
	else if(out_valid) cnt <= 31;
	else if((cnt_global == 11 || cnt_global == 47) ) cnt <= 1;   
	else if(~&cnt) cnt <= cnt + 1;                              
end
//input reg

always@(posedge clk) begin
	img_reg[11] <= img;
	for(i=0;i<11;i=i+1) img_reg[i] <= img_reg[i+1];
end


always@(posedge clk)begin
	if( cnt_global < 9)begin
		for(i=0;i<9;i=i+1)begin
			if(i==cnt_global) ker_reg[i] <= ker;
		end
	end
end

always@(posedge clk)begin
	if( cnt_global < 4 )begin
		 weight_reg[cnt_global[1:0]] <= weight;
	end
end
//img window enable



always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<9;i=i+1) window_en[i] <= 0;
	end
	else begin
		for(i=0;i<9;i=i+1) window_en[i] <= 1;
	end
end
//img mux
always@(*)begin
	if( window_en[0]   ) begin
		
		if(cnt[3:0] == 1 || cnt[3:0] == 2 ||cnt[3:0] == 3 ||cnt[3:0] == 4)  ifm[0] = img_reg[0];
		else ifm[0] = ifm_3to0;

	end
	else ifm[0] = 0;
end

always@(*)begin
	if( window_en[1]   ) begin
		case(cnt[3:0])
		4'd5,4'd2,4'd3,4'd4: ifm[1] = img_reg[0];
		default: ifm[1] = ifm_4to1;
		endcase
	end
	else ifm[1] = 0;
end

always@(*)begin
	if( window_en[2]  ) begin
		case(cnt[3:0])
		4'd5,4'd6,4'd3,4'd4: ifm[2] = img_reg[0];
		default: ifm[2] = ifm_5to2;
		endcase
	end
	else ifm[2] = 0;
end

always@(*)begin
	if( window_en[3]  ) begin
		case(cnt[3:0])
		4'd5,4'd6,4'd7,4'd4: ifm[3] = img_reg[3];
		default: ifm[3] = ifm_6to3;
		endcase
	end
	else ifm[3] = 0;
end

always@(*)begin
	if( window_en[4] ) begin
		case(cnt[3:0])
		4'd5,4'd6,4'd7,4'd8: ifm[4] = img_reg[3];
		default: ifm[4] = ifm_7to4;
		endcase
	end
	else ifm[4] = 0;
end

always@(*)begin
	if(window_en[5] ) begin
		case(cnt[3:0])
		4'd9,4'd6,4'd7,4'd8: ifm[5] = img_reg[3];
		default: ifm[5] = ifm_8to5;
		endcase
	end
	else ifm[5] = 0;
end

always@(*)begin
	if(window_en[6] ) begin
		case (cnt[3:0])
		4'd7,4'd8,4'd9,4'd10: ifm[6] = img_reg[6];
		4'd11,4'd12,4'd13,4'd14: ifm[6] = img_reg[8];
		4'd15,4'd0,4'd1,4'd2: ifm[6] = img_reg[10];
		4'd3,4'd4,4'd5,4'd6: ifm[6] = img;// img_reg[12];
		endcase
	end
	else ifm[6] = 0;
end

always@(*)begin
	if(window_en[7] ) begin
		case (cnt[3:0])
		4'd8,4'd9,4'd10,4'd11: ifm[7] = img_reg[6];
		4'd12,4'd13,4'd14,4'd15: ifm[7] = img_reg[8];
		4'd0,4'd1,4'd2,4'd3: ifm[7] = img_reg[10];
		4'd4,4'd5,4'd6,4'd7: ifm[7] = img;//img_reg[12];
		endcase
	end
	else ifm[7] = 0;
end

always@(*)begin
	if( window_en[8] ) begin
		case (cnt[3:0])
		4'd9,4'd10,4'd11,4'd12: ifm[8] = img_reg[6];
		4'd13,4'd14,4'd15,4'd0: ifm[8] = img_reg[8];
		4'd1,4'd2,4'd3,4'd4: ifm[8] = img_reg[10];
		4'd5,4'd6,4'd7,4'd8: ifm[8] = img;//img_reg[12];
		endcase
	end
	else ifm[8] = 0;
end


always@(posedge clk) begin
	ifm_3to0 <= ifm[3];
end
always@(posedge clk) begin
	ifm_4to1 <= ifm[4];
end
always@(posedge clk) begin
	ifm_5to2 <= ifm[5];
end
always@(posedge clk) begin
	ifm_6to3 <= ifm[6];
end
always@(posedge clk) begin
	ifm_7to4 <= ifm[7];
end
always@(posedge clk) begin
	ifm_8to5 <= ifm[8];
end


//convolution
wire [19:0] addmult[0:9];
assign addmult[0] = 0;
genvar c;
generate
	for(c=0;c<9;c=c+1) begin
		add_mult my_conv (.a(addmult[c]),.b(ifm[c]),.c(ker_reg[c]),.clk(clk),.out(addmult[c+1]));
	end
endgenerate

//quantization
reg [7:0]  quant1;
always@(*) quant1 <= addmult[9] / 2295;

//line buffer
reg [7:0] buffer[0:4];


always@(posedge clk)begin
	buffer[4] <= quant1;
	buffer[3] <= buffer[4];
	buffer[2] <= buffer[3];
	buffer[1] <= buffer[2];
	buffer[0] <= buffer[1];
end
//max pooling && fully connected
//max pooling && fully connected
wire[7:0] max_temp1,max_temp2,max_comb;
reg [7:0] max;
wire[7:0] mult_in;
wire[7:0] weight1,weight2;
reg[15:0] mult_temp1,mult_temp2;
wire[16:0]add_in1,add_in2; 
wire[16:0] add_temp1,add_temp2;
wire[15:0] a,b;


assign max_temp1 = (buffer[4] > quant1)? buffer[4] : quant1;
assign max_temp2 = (buffer[1] > buffer[0])? buffer[1] : buffer[0];
assign max_comb = (max_temp1 > max_temp2)? max_temp1 : max_temp2;

always@(posedge clk) max <= max_comb;

assign weight1 = (cnt == 16 || cnt == 24)? weight_reg[0] : weight_reg[2];
assign weight2 = (cnt == 16 || cnt == 24)? weight_reg[1] : weight_reg[3];
//assign mult_in = (cnt == 28 || cnt == 30 || cnt == 36 || (cnt == 2 && !flag) || cnt == 38 )? max : 0;   
assign a = max * weight1;
assign b = max * weight2;

//assign add_in1 = (cnt == 29)?  : fc[2];
//assign add_in2 = (cnt == 29)? fc[1] : fc[3];
assign add_temp1 = (cnt == 18 ||  cnt == 26)? a + mult_temp1:0;
assign add_temp2 = (cnt == 18 ||  cnt == 26)? b + mult_temp2:0;

always@(posedge clk) begin
	if(cnt == 16 || cnt == 24)begin
		mult_temp1 <= a;
		mult_temp2 <= b;
	end
end

//quantization2
wire[7:0] encode_comb[0:1];
reg [7:0] encode_reg[0:3];
always@(posedge clk)begin
	if(cnt_global == 29 ) begin
		encode_reg[0] <= encode_comb[0];
		encode_reg[1] <= encode_comb[1];
	end
	if(cnt_global == 37) begin
		encode_reg[2] <= encode_comb[0];
		encode_reg[3] <= encode_comb[1];
	end
end
quantization_2 my_quantization_2_1 (.a(add_temp1), .out(encode_comb[0]));
quantization_2 my_quantization_2_2 (.a(add_temp2), .out(encode_comb[1]));


//L1 distance
reg  [7:0] l1_sub_in1,l1_sub_in2;
wire [7:0] l1_add_in1, l1_add_in2,l1_add_in3;
wire [9:0] l1_sub_temp1,l1_sub_temp2;
wire [9:0] l1_add_temp;
reg  [9:0] l1_reg;

always@(*) begin
	if(cnt_global == 65) l1_sub_in1 = encode_reg[0];
	else l1_sub_in1 =  encode_reg[2];

end

always@(*) begin
	if(cnt_global == 65 ) l1_sub_in2 = encode_reg[1];
	else l1_sub_in2 =  encode_reg[3];
end

assign l1_sub_temp1 = l1_sub_in1 - encode_comb[0];
assign l1_sub_temp2 = l1_sub_in2 - encode_comb[1];

assign l1_add_in1 = (l1_sub_temp1[9])? -l1_sub_temp1 : l1_sub_temp1;
assign l1_add_in2 = (l1_sub_temp2[9])? -l1_sub_temp2 : l1_sub_temp2;
assign l1_add_in3 =  l1_add_in1 + l1_add_in2;
assign l1_add_temp = l1_reg + l1_add_in3;
always@(posedge clk)begin
	if(cnt_global == 65)
	l1_reg <= l1_add_in3;
end




//if in_valid uncontinous ,output 0 whatever, fuck you 
reg JG_fuckyou;
reg [9:0] n_output;
/*
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) JG_fuckyou <= 0;
	else if(cnt_global>0 && cnt_global < 72 && !in_valid) JG_fuckyou <= 1;
	//else if(out_valid) 
end*/
//if in_valid uncontinous ,output 0 whatever, fuck you 
always@(*)begin
	//if(JG_fuckyou) n_output = 0;
	 if(|l1_add_temp[9:4]) n_output = l1_add_temp;
	else n_output = 0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
		out_data <= 0;
	end
	else if(cnt_global == 73)begin
		out_valid <= 1;
		out_data <=n_output;//l1_add_temp:0;// n_output;//
	end
	else begin
		out_valid <= 0;
		out_data <= 0;
	end
end

endmodule

module add_mult(a,b,c,clk,out);
	input clk;
	input [19:0] a;
	input [7:0] b,c;
	output reg [19:0] out;
	always@(posedge clk ) begin
		out <= (a + b * c);
	end
endmodule
/*
module conv_quant(a,b,c,clk,out);
	input clk;
	input [19:0] a;
	input [7:0] b,c;
	output reg [7:0] out;
	always@(posedge clk ) begin
		out <= (a + b * c)/2295;
	end
endmodule
*/
module quantization_2(a,out);
	//input clk;
	input [16:0] a;
	output reg [7:0] out;
	always@(*)begin//(posedge clk) begin
		out <= a / 510;
	end
endmodule

//10 11 ,14 15   , 2 3 , 6 7      , 010  011 110 111
//12 13 ,16 17   , 4 5 , 0 ,1
/*
reg [7:0] max_left,max_right;
reg [7:0] max_left_temp,max_right_temp;
always@(*)begin
	max_left_temp = (quant1 > max_left)? quant1 : max_left;
	max_right_temp = (quant1 > max_right)? quant1 : max_right;
end
always@(posedge clk)begin
	if(cnt[2:0] == 2) max_left <= quant1;
	else if(cnt[2:0] == 6 || cnt[2:0] == 3 ) max_left <= max_left_temp;
end

always@(posedge clk)begin
	if(cnt[2:0] == 4) max_right <= quant1;
	else if( cnt[2:0] == 0 || cnt[2:0] == 5) max_right <= max_right_temp;
end	

always@(posedge clk)begin
	max <= (&cnt[2:0])? max_left_temp : max_right_temp;
end*/
