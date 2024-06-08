//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2024 ICLAB Spring Course
//   Lab11      : SNN
//   Author     : ZONG-RUI CAO
//   File       : PATTERN_CG.v (w/ CG, cg_en = 1)
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   DESCRIPTION: 2024 Spring IC Lab / Exercise Lab11 / SNN
//   Release version : v1.0 (Release Date: May-2024)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define CYCLE_TIME   15
`define CG_EN         0
`define PATTERN_NUMBER   100
`define SEED_NUMBER     28825252

module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Input signals
	out_valid,
	out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [7:0] img;
output reg [7:0] ker;
output reg [7:0] weight;

input out_valid;
input  [9:0] out_data;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
real PATNUM = `PATTERN_NUMBER;
real seed = `SEED_NUMBER;
integer latency,total_latency;
integer i_pat, a,b,c;
integer i,j,k;
//================================================================
// Wire & Reg Declaration
//================================================================
reg [7:0] flatten_img[0:71];
reg [7:0] flatten_ker[0:8];
reg [7:0] flatten_weight[0:3];
reg [7:0] in_img[0:1][0:5][0:5];
reg [7:0] in_ker[0:2][0:2];
reg [7:0] in_weight[0:1][0:1];
reg [19:0] conv[0:1][0:3][0:3];
reg [7:0]  conv_quant[0:1][0:3][0:3];
reg [7:0] mp [0:1][0:1][0:1];
reg [16:0] fc [0:1][0:3];  //flatten
reg [7:0]  fc_quant [0:1][0:3];
reg [9:0]  L1 , activation , golden_ans;
//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2) clk = ~clk;

//================================================================
// task
//================================================================

initial begin
	total_latency = 0;
    reset_task;
    @(negedge clk);
	for(i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
		input_task;
		wait_out_valid_task;
        check_ans_task;
		repeat(1) @(negedge clk);
        $display("pass pattern No.%d, latency: %d" ,i_pat,latency );
        total_latency = total_latency + latency;
	end
	PASS_task;
end


task reset_task; begin
    in_valid = 0;
    img = 'bx;
    ker = 'bx;
    weight = 'bx;
    rst_n = 1;
	cg_en = 0 ;
    force clk = 0;
    #(CYCLE); rst_n = 0;
    #(CYCLE * 5); rst_n = 1;
    if(out_data !== 0 || out_valid !== 0) begin
        $display("Error: Reset Task");
        $finish;
    end
    #(CYCLE); release clk;
end
endtask


task input_task;begin
	for(c = 0; c < 2 ; c = c + 1) 
		for(a = 0; a < 6; a = a + 1) 
			for(b = 0; b < 6; b = b + 1) 
				in_img[c][a][b] = $random(seed)%256;

    for(a = 0; a < 3; a = a + 1)
		for(b = 0; b < 3; b = b + 1)
			in_ker[a][b] = $random(seed)%256;

	for(a = 0; a < 2; a = a + 1)
		for(b = 0; b < 2; b = b + 1)
			in_weight[a][b] = $random(seed)%256;


    repeat($random(seed)%4) @(negedge clk);

	

	for(c = 0; c < 2 ; c = c + 1)
		for(a = 0; a < 6; a = a + 1)
			for(b = 0; b < 6; b = b + 1)
				flatten_img[a*6+b+c*36] = in_img[c][a][b];
	for(a = 0; a < 3; a = a + 1)
		for(b = 0; b < 3; b = b + 1)
			flatten_ker[a*3+b] = in_ker[a][b];
	for(a = 0; a < 2; a = a + 1)
		for(b = 0; b < 2; b = b + 1)
			flatten_weight[a*2+b] = in_weight[a][b];

    for(a = 0;a<72;a=a+1)begin
		cg_en = `CG_EN ;
        in_valid = 1;
		img = flatten_img[a];


        if(a<9)  ker = flatten_ker[a];
		else ker = 'bx;

		if(a<4)  weight = flatten_weight[a];
		else weight = 'bx;	

        @(negedge clk);
    end
    in_valid = 0;
    img = 'bx;
    ker = 'bx;
    weight = 'bx;
end endtask

task wait_out_valid_task;begin
    latency = -1;
    while(out_valid !== 1)begin
        if(latency == 1000)begin
            $display("ERROR!Out_valid is not 1 after 1000 cycles");
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
end endtask


task check_ans_task; begin
	if(out_data !== golden_ans) begin
		$display("Error: pattern No.%d, out_data: %d, golden_ans: %d",i_pat,out_data,golden_ans);
		$finish;
	end
	@(negedge clk);
	if(out_valid !== 0) begin
		$display("out_valid longer than 1 cycle");
		$finish;
	end
end endtask

always@(negedge clk) begin
	if(out_valid ===0 && out_data !== 0) begin
		$display("Error: out_data should be  0 when out_valid is 0");
		$finish;
	end
end


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
//================================================================
// SNN computation
//================================================================
//conv
always@(*)begin
	for(k = 0; k < 2; k=k+1)
		for(i = 0; i < 4; i=i+1)
			for(j = 0; j < 4; j=j+1) begin:convolution
					conv[k][i][j] = in_img[k][i][j] * in_ker[0][0] + in_img[k][i][j+1] * in_ker[0][1] + in_img[k][i][j+2] * in_ker[0][2] + 
									in_img[k][i+1][j] * in_ker[1][0] + in_img[k][i+1][j+1] * in_ker[1][1] + in_img[k][i+1][j+2] * in_ker[1][2] + 
									in_img[k][i+2][j] * in_ker[2][0] + in_img[k][i+2][j+1] * in_ker[2][1] + in_img[k][i+2][j+2] * in_ker[2][2];
			end
end
//quantization1
localparam scale1 = 2295;
always@(*)begin
	for(k = 0; k < 2; k=k+1)
		for(i = 0; i < 4; i=i+1)
			for(j = 0; j < 4; j=j+1) begin:conv_quantization
				conv_quant[k][i][j] = conv[k][i][j] / scale1; 
			end
end
//mp
reg [7:0] max_temp1,max_temp2;
always@(*)begin
	for(k = 0; k < 2; k=k+1)
		for(i = 0; i < 2; i=i+1)
			for(j = 0; j < 2; j=j+1) begin:max_pooling
				max_temp1 = (conv_quant[k][i*2][j*2] > conv_quant[k][i*2+1][j*2])? conv_quant[k][i*2][j*2] : conv_quant[k][i*2+1][j*2];
				max_temp2 = (conv_quant[k][i*2][j*2+1]>conv_quant[k][i*2+1][j*2+1])? conv_quant[k][i*2][j*2+1] : conv_quant[k][i*2+1][j*2+1];
				mp[k][i][j] = (max_temp1 > max_temp2)? max_temp1 : max_temp2;
			end
end
//fc
always@(*)begin
	for(k = 0; k < 2; k=k+1)
		for(i = 0; i < 4; i=i+1)
			fc[k][i] = mp[k][i/2][0] * in_weight[0][i%2] + mp[k][i/2][1] * in_weight[1][i%2];
end
//quantization2
localparam scale2 = 510;
always@(*)begin
	for(k = 0; k < 2; k=k+1)
		for(i = 0; i < 4; i=i+1)
			fc_quant[k][i] = fc[k][i] / scale2;
end
//L1
reg [9:0] L1_sub_temp1,L1_sub_temp2,L1_sub_temp3,L1_sub_temp4;
reg [9:0] L1_pos1,L1_pos2,L1_pos3,L1_pos4;
always@(*)begin
	L1_sub_temp1 = (fc_quant[0][0] - fc_quant[1][0]);
	L1_sub_temp2 = (fc_quant[0][1] - fc_quant[1][1]);
	L1_sub_temp3 = (fc_quant[0][2] - fc_quant[1][2]);
	L1_sub_temp4 = (fc_quant[0][3] - fc_quant[1][3]);
	L1_pos1 = (L1_sub_temp1[9])? ~L1_sub_temp1 + 1: L1_sub_temp1;
	L1_pos2 = (L1_sub_temp2[9])? ~L1_sub_temp2 + 1: L1_sub_temp2;
	L1_pos3 = (L1_sub_temp3[9])? ~L1_sub_temp3 + 1: L1_sub_temp3;
	L1_pos4 = (L1_sub_temp4[9])? ~L1_sub_temp4 + 1: L1_sub_temp4;
	L1 = L1_pos1 + L1_pos2 + L1_pos3 + L1_pos4;
	activation = (L1 >= 16)? L1 : 0;
	golden_ans = activation;

end

endmodule