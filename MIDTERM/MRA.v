//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/
parameter ID_WIDTH=4;
parameter DATA_WIDTH=128;
parameter ADDR_WIDTH=32 ;  //0x00000000 to  0x0002FFFF
// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;  //no need
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;  //no need
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;		 //no need
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;  //no need
// -----------------------------
// ===============================================================
//  					reg && wire
// ===============================================================
//parameter//
integer i,j;
parameter IDLE = 4'd0;
parameter STORE_INPUT_WRITE_MAP = 4'd1;
parameter WRITE_WEIGHT = 4'd2;
parameter SOURCE_SINK = 4'd3;
parameter PROPAGATION = 4'd4;
parameter RETRACE_SRAM_READ = 4'd5;
parameter WRITE_SRAM = 4'd6;
parameter WRITE_DRAM = 4'd7;
parameter RESET_MAP = 4'd8;
parameter START_RETRACE = 4'd9;
//input
reg cnt_input;
reg [3:0] cnt_net;
reg [4:0] frame_id_reg;
reg [3:0] net_id_reg[0:14];
reg [5:0] loc_x_start[0:14];
reg [5:0] loc_y_start[0:14];
reg [5:0] loc_x_end[0:14];
reg [5:0] loc_y_end[0:14];
//select current path (x,y)
reg [3:0] cnt_path;
//propagation counter
reg [1:0] cnt_propagation;
reg [1:0] n_cnt_propagation;
//2233 mapping
reg [1:0] map_propagation_2233 [0:63][0:63];
//RETRACE_SRAM_READ
reg [5:0] new_y,new_x;
wire [5:0] top,bot,right,left;
reg [1:0] flag_top,flag_bot,flag_right,flag_left;
//128 bit cnt
reg [6:0] cnt_sram_addr;
//state//
reg [3:0] c_state, n_state;
// ===============================================================
//  					FSM
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		c_state <= IDLE;
	end
	else begin
		c_state <= n_state;
	end
end

always@(*)begin
	case(c_state)
	IDLE:begin
		if(in_valid)begin
			n_state = STORE_INPUT_WRITE_MAP;
		end
		else begin
			n_state = IDLE;
		end
	
	end
	STORE_INPUT_WRITE_MAP:begin
		if(rlast_m_inf)begin
			n_state = WRITE_WEIGHT;
		end
		else begin
			n_state = STORE_INPUT_WRITE_MAP;
		end
	end
	WRITE_WEIGHT:begin
		if(rlast_m_inf)begin
			n_state = SOURCE_SINK;
		end
		else begin
			n_state = WRITE_WEIGHT;
		end
	end
	RESET_MAP:begin		//finish or not
		//if(cnt_net == 0) n_state = WRITE_DRAM;
		//else n_state = SOURCE_SINK;
		n_state = SOURCE_SINK;
	end
	SOURCE_SINK:begin  //another path start
		if(cnt_net == 0) n_state = WRITE_DRAM;
		else n_state = PROPAGATION;
	end
	PROPAGATION:begin
		if(map_propagation_2233[loc_y_end[0]][loc_x_end[0]][1])begin
			n_state = START_RETRACE;
		end
		else begin
			n_state = PROPAGATION;
		end
	end
	START_RETRACE:begin
		n_state = RETRACE_SRAM_READ;
	end
	RETRACE_SRAM_READ:begin
			n_state = WRITE_SRAM;
	end
	WRITE_SRAM:begin
		if(!map_propagation_2233[loc_y_start[0]][loc_x_start[0]][1]) begin
			n_state = RESET_MAP;
		end
		else	n_state = RETRACE_SRAM_READ;
	end
	WRITE_DRAM:begin
		if(bvalid_m_inf)begin
			n_state = IDLE;
		end
		else begin
			n_state = WRITE_DRAM;
		end
	end
	default: n_state = IDLE;

	endcase
end
// ===============================================================
//  					INPUT REG
// ===============================================================

//frame_id
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		frame_id_reg <= 0;
	end
	else if(in_valid)begin
		frame_id_reg <= frame_id;
	end
	else begin
		frame_id_reg <= frame_id_reg;
	end
end
//cnt_input
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) cnt_input <= 0;
	else if(in_valid) cnt_input <= !cnt_input;
	else cnt_input <= 0;
end
//cnt_net
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) cnt_net <= 0;
	else if(cnt_input && c_state == STORE_INPUT_WRITE_MAP) cnt_net <= cnt_net + 1;
	else if(c_state == RESET_MAP) cnt_net <= cnt_net - 1;
	else cnt_net <= cnt_net;
end
//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<15;i=i+1)begin
			net_id_reg[i] <= 0;
			loc_x_start[i] <= 0;
			loc_y_start[i] <= 0;
			loc_x_end[i] <= 0;
			loc_y_end[i] <= 0;
		end
	end
	else if(in_valid && !cnt_input)begin
		net_id_reg[cnt_net] <= net_id;
		loc_x_start[cnt_net] <= loc_x;
		loc_y_start[cnt_net] <= loc_y;
	end
	else if(in_valid) begin
		loc_x_end[cnt_net] <= loc_x;
		loc_y_end[cnt_net] <= loc_y;
	end
	else if( c_state == RESET_MAP)begin  //after one path is done, shift the reg and begin next path
		for(i=0;i<14;i=i+1)begin
			net_id_reg[i] <= net_id_reg[i+1];
			loc_x_start[i] <= loc_x_start[i+1];
			loc_y_start[i] <= loc_y_start[i+1];
			loc_x_end[i] <= loc_x_end[i+1];
			loc_y_end[i] <= loc_y_end[i+1];
		end
	end
end
// ===============================================================
//  					2233 mapping
// ===============================================================
//cnt_propagation
always@(*) begin
	if(c_state == START_RETRACE)								n_cnt_propagation = cnt_propagation - 3;
	else if(c_state == PROPAGATION)								n_cnt_propagation = cnt_propagation + 1;
	else if(c_state == WRITE_SRAM)								n_cnt_propagation = cnt_propagation - 1;
	else if(c_state == RESET_MAP) 								n_cnt_propagation = 0; 
	else 														n_cnt_propagation = cnt_propagation;
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) cnt_propagation <= 0;
	else cnt_propagation <= n_cnt_propagation;
end
//map_propagation_2233
always@(posedge clk)begin
	if(rready_m_inf && c_state == STORE_INPUT_WRITE_MAP) begin
		for(i=0;i<32;i=i+1)begin
			if(cnt_sram_addr[0] == 0)			map_propagation_2233[cnt_sram_addr[6:1]][i] <=  |rdata_m_inf[i*4+3-:4];
			else 								map_propagation_2233[cnt_sram_addr[6:1]][i+32] <= |rdata_m_inf[i*4+3-:4];
		end
	end
	else if(c_state == SOURCE_SINK)begin
			map_propagation_2233[loc_y_start[0]][loc_x_start[0]] <=  3;
			map_propagation_2233[loc_y_end[0]][loc_x_end[0]] <= 0;
	end
	else if(c_state == RESET_MAP)begin
		for(i=0;i<64;i=i+1)
			for(j=0;j<64;j=j+1) begin
				if(map_propagation_2233[i][j][1] == 1)	map_propagation_2233[i][j] <= 0;
				else 									map_propagation_2233[i][j] <= map_propagation_2233[i][j];
			end
	end
	
	else if(c_state == PROPAGATION)begin
		for(i=1;i<63;i=i+1)begin
			for(j=1;j<63;j=j+1)begin
				if( (map_propagation_2233[i][j+1][1] || map_propagation_2233[i][j-1][1] || map_propagation_2233[i+1][j][1] || map_propagation_2233[i-1][j][1] ) &&  map_propagation_2233[i][j]==0 )begin
					map_propagation_2233[i][j] <= {1'b1,cnt_propagation[1]};
				end
				else begin
					map_propagation_2233[i][j] <= map_propagation_2233[i][j];
				end
			end
		end

		map_propagation_2233[0][63] <= ((map_propagation_2233[0][62][1] || map_propagation_2233[1][63][1])  && map_propagation_2233[0][63]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[0][63];
		map_propagation_2233[63][63]<= ((map_propagation_2233[63][62][1]|| map_propagation_2233[62][63][1]) && map_propagation_2233[63][63]==0)? {1'b1,cnt_propagation[1]} : map_propagation_2233[63][63];
		map_propagation_2233[63][0] <= ((map_propagation_2233[62][0][1] || map_propagation_2233[63][1][1])  && map_propagation_2233[63][0]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[63][0];
		map_propagation_2233[0][0] <=  ((map_propagation_2233[0][1][1]  || map_propagation_2233[1][0][1])   && map_propagation_2233[0][0]==0  )? {1'b1,cnt_propagation[1]} : map_propagation_2233[0][0];

		for(i=1;i<63;i=i+1)begin
			map_propagation_2233[i][0] <= ((map_propagation_2233[i][1][1] || map_propagation_2233[i+1][0][1] || map_propagation_2233[i-1][0][1]) && map_propagation_2233[i][0]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[i][0];
			map_propagation_2233[i][63] <= ((map_propagation_2233[i][62][1] || map_propagation_2233[i+1][63][1] || map_propagation_2233[i-1][63][1]) && map_propagation_2233[i][63]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[i][63];
		end

		for(i=1;i<63;i=i+1)begin
			map_propagation_2233[0][i] <= ((map_propagation_2233[0][i+1][1] || map_propagation_2233[1][i][1] || map_propagation_2233[0][i-1][1]) && map_propagation_2233[0][i]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[0][i];
			map_propagation_2233[63][i] <= ((map_propagation_2233[63][i+1][1] || map_propagation_2233[62][i][1] || map_propagation_2233[63][i-1][1]) && map_propagation_2233[63][i]==0 )? {1'b1,cnt_propagation[1]} : map_propagation_2233[63][i];
		end
	end
	else if(c_state == RETRACE_SRAM_READ) begin
		map_propagation_2233[new_y][new_x] <= 1;        //RETRACE_SRAM_READ_from end (xy) to start (xy)
	end
	end
// RETRACE_SRAM_READ , new_y,new_x

assign top = new_y + 1;
assign bot = new_y - 1;
assign right = new_x + 1;
assign left = new_x - 1;

always@(posedge clk)begin
	flag_top <= map_propagation_2233[top][new_x];
	flag_bot <= map_propagation_2233[bot][new_x];
	flag_right <= map_propagation_2233[new_y][right];
	flag_left <= map_propagation_2233[new_y][left];
	//if(map_propagation_2233[top][new_x] == {1'b1,cnt_propagation[1]} && !top[6])	flag_top <= 1;
	//else flag_top <= 0;
	
	//if(map_propagation_2233[bot][new_x] == {1'b1,cnt_propagation[1]} && !bot[6]) flag_bot <= 1;
	//else flag_bot <= 0;

	//if(map_propagation_2233[new_y][right] == {1'b1,cnt_propagation[1]} && !right[6]) flag_right <= 1;
	//else flag_right <= 0;
	
	//if(map_propagation_2233[new_y][left] == {1'b1,cnt_propagation[1]} && !left[6]) flag_left <= 1;
	//else flag_left <= 0;
end

always@(posedge clk) begin
	if(c_state == SOURCE_SINK)begin
		new_y <= loc_y_end[0];
		new_x <= loc_x_end[0];
	end
	else if(c_state == WRITE_SRAM)begin
		if(flag_top == {1'b1,cnt_propagation[1]} && new_y != 63 )begin
			new_y <= top;
			new_x <= new_x;
		end
		else if(flag_bot == {1'b1,cnt_propagation[1]} && new_y != 0)begin
			new_y <= bot;
			new_x <= new_x;
		end
		else if(flag_right == {1'b1,cnt_propagation[1]} && new_x != 63)begin
			new_y <= new_y;
			new_x <= right;
		end
		else if(flag_left == {1'b1,cnt_propagation[1]} && new_x != 0)begin
			new_y <= new_y;
			new_x <= left;
		end
	end
end

// ===============================================================
//  					SRAM 1
// ===============================================================
//addr cnt
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt_sram_addr <= 0;
	end
	else if(rvalid_m_inf ||  wready_m_inf || (awready_m_inf && awvalid_m_inf) )begin
		cnt_sram_addr <= cnt_sram_addr + 1;
	end
	else if(c_state ==IDLE)begin
		cnt_sram_addr <= 0;
	end
	else begin
		cnt_sram_addr <= cnt_sram_addr;
	end
end
// need fix, write sram
wire [63:0] data_in_1,data_in_2;
reg [7:0] addr_in_1 , addr_in_2;
wire write_en_1, write_en_2;
wire [63:0] data_out_1, data_out_2;
wire [6:0] add1;
reg [63:0] new_data_in;
reg [63:0] weight_select;
wire [63:0] data_out_map,data_out_weight;

assign data_out_map =    (new_x[4])? data_out_2 : data_out_1;
assign data_out_weight = (new_x[4])? data_out_1 : data_out_2;
always@(*)begin
	case(new_x[3:0])
	4'd0: new_data_in =  {data_out_map[63:4],net_id_reg[0]};
	4'd1: new_data_in =  {data_out_map[63:8],net_id_reg[0],data_out_map[3:0]};
	4'd2: new_data_in =  {data_out_map[63:12],net_id_reg[0],data_out_map[7:0]};
	4'd3: new_data_in =  {data_out_map[63:16],net_id_reg[0],data_out_map[11:0]};
	4'd4: new_data_in =  {data_out_map[63:20],net_id_reg[0],data_out_map[15:0]};
	4'd5: new_data_in =  {data_out_map[63:24],net_id_reg[0],data_out_map[19:0]};
	4'd6: new_data_in =  {data_out_map[63:28],net_id_reg[0],data_out_map[23:0]};
	4'd7: new_data_in =  {data_out_map[63:32],net_id_reg[0],data_out_map[27:0]};
	4'd8: new_data_in =  {data_out_map[63:36],net_id_reg[0],data_out_map[31:0]};
	4'd9: new_data_in =  {data_out_map[63:40],net_id_reg[0],data_out_map[35:0]};
	4'd10: new_data_in = {data_out_map[63:44],net_id_reg[0],data_out_map[39:0]};
	4'd11: new_data_in = {data_out_map[63:48],net_id_reg[0],data_out_map[43:0]};
	4'd12: new_data_in = {data_out_map[63:52],net_id_reg[0],data_out_map[47:0]};
	4'd13: new_data_in = {data_out_map[63:56],net_id_reg[0],data_out_map[51:0]};
	4'd14: new_data_in = {data_out_map[63:60],net_id_reg[0],data_out_map[55:0]};
	4'd15: new_data_in = {net_id_reg[0],data_out_map[59:0]};
	endcase
end

always@(*)begin
	case(new_x[3:0])
	4'd0: weight_select = data_out_weight[3:0];
	4'd1: weight_select = data_out_weight[7:4];
	4'd2: weight_select = data_out_weight[11:8];
	4'd3: weight_select = data_out_weight[15:12];
	4'd4: weight_select = data_out_weight[19:16];
	4'd5: weight_select = data_out_weight[23:20];
	4'd6: weight_select = data_out_weight[27:24];
	4'd7: weight_select = data_out_weight[31:28];
	4'd8: weight_select = data_out_weight[35:32];
	4'd9: weight_select = data_out_weight[39:36];
	4'd10: weight_select = data_out_weight[43:40];
	4'd11: weight_select = data_out_weight[47:44];
	4'd12: weight_select = data_out_weight[51:48];
	4'd13: weight_select = data_out_weight[55:52];
	4'd14: weight_select = data_out_weight[59:56];
	4'd15: weight_select = data_out_weight[63:60];
	endcase
end

assign add1 = cnt_sram_addr+1;
assign data_in_1 = (c_state == STORE_INPUT_WRITE_MAP)? rdata_m_inf[63:0]   : (c_state == WRITE_WEIGHT)? rdata_m_inf[127:64] :new_data_in;  //location && weight stored at diff sram
assign data_in_2 = (c_state == STORE_INPUT_WRITE_MAP)? rdata_m_inf[127:64] : (c_state == WRITE_WEIGHT)? rdata_m_inf[63:0]   :new_data_in;
//assign addr_in_1 = (c_state == STORE_INPUT_WRITE_MAP|| c_state == WRITE_DRAM)? {cnt_sram_addr[6:0],1'b1} : {cnt_sram_addr[6:0],1'b0};    //SRAM1: map store 1,3,5,7,9,11,13,15 ....  weight store 0 2 4 ... 
//assign addr_in_2 = (c_state == STORE_INPUT_WRITE_MAP|| c_state == WRITE_DRAM)? {cnt_sram_addr[6:0],1'b1} : {cnt_sram_addr[6:0],1'b0};    //SRAM2:   
always@(*)begin
	if(wready_m_inf && wvalid_m_inf)begin   //write sram back to DRAM
		addr_in_1 = {add1,1'b1};
		addr_in_2 = {add1,1'b1};
	end
	else if(c_state == STORE_INPUT_WRITE_MAP || c_state == WRITE_DRAM)begin
		addr_in_1 = {cnt_sram_addr[6:0],1'b1};
		addr_in_2 = {cnt_sram_addr[6:0],1'b1};
	end
	else if(c_state == WRITE_WEIGHT)begin
		addr_in_1 = {cnt_sram_addr[6:0],1'b0};
		addr_in_2 = {cnt_sram_addr[6:0],1'b0};
	end
	else if(!new_x[4])begin                        // front 16 element , 0~15 or 32~47
		addr_in_1 = {new_y[5:0],new_x[5],1'b1};    //  new_x[3:0]      ,256 --> {new_y[5:0],new_x[5],1'b1};
		addr_in_2 = {new_y[5:0],new_x[5],1'b0};    //  data_1 is location, data_2 is weight
	end
	else begin                                     // back 16 element , 16~31 or 48~63
		addr_in_1 = {new_y[5:0],new_x[5],1'b0}; // data_1 is weight, data_2 is location
		addr_in_2 = {new_y[5:0],new_x[5],1'b1}; 
	end
end
assign write_en_1 = ( (rvalid_m_inf && (c_state == STORE_INPUT_WRITE_MAP || c_state == WRITE_WEIGHT ))  || (c_state == WRITE_SRAM  && !new_x[4]))? 0 : 1;
assign write_en_2 = ( (rvalid_m_inf && (c_state == STORE_INPUT_WRITE_MAP || c_state == WRITE_WEIGHT ))  || (c_state == WRITE_SRAM  &&  new_x[4]))? 0 : 1;

Map_256X64X1BM1 ur_map(.A0(addr_in_1[0]),.A1(addr_in_1[1]),.A2(addr_in_1[2]),.A3(addr_in_1[3]),.A4(addr_in_1[4]),.A5(addr_in_1[5]),.A6(addr_in_1[6]),.A7(addr_in_1[7]),
				.DO0(data_out_1[0]),.DO1(data_out_1[1]),.DO2(data_out_1[2]),.DO3(data_out_1[3]),.DO4(data_out_1[4]),.DO5(data_out_1[5]),.DO6(data_out_1[6]),.DO7(data_out_1[7]),.DO8(data_out_1[8]),
				.DO9(data_out_1[9]),.DO10(data_out_1[10]),.DO11(data_out_1[11]),.DO12(data_out_1[12]),.DO13(data_out_1[13]),.DO14(data_out_1[14]),.DO15(data_out_1[15]),.DO16(data_out_1[16]),
				.DO17(data_out_1[17]),.DO18(data_out_1[18]),.DO19(data_out_1[19]),.DO20(data_out_1[20]),.DO21(data_out_1[21]),.DO22(data_out_1[22]),.DO23(data_out_1[23]),.DO24(data_out_1[24]),
				.DO25(data_out_1[25]),.DO26(data_out_1[26]),.DO27(data_out_1[27]),.DO28(data_out_1[28]),.DO29(data_out_1[29]),.DO30(data_out_1[30]),.DO31(data_out_1[31]),.DO32(data_out_1[32]),
				.DO33(data_out_1[33]),.DO34(data_out_1[34]),.DO35(data_out_1[35]),.DO36(data_out_1[36]),.DO37(data_out_1[37]),.DO38(data_out_1[38]),.DO39(data_out_1[39]),.DO40(data_out_1[40]),
				.DO41(data_out_1[41]),.DO42(data_out_1[42]),.DO43(data_out_1[43]),.DO44(data_out_1[44]),.DO45(data_out_1[45]),.DO46(data_out_1[46]),.DO47(data_out_1[47]),.DO48(data_out_1[48]),
				.DO49(data_out_1[49]),.DO50(data_out_1[50]),.DO51(data_out_1[51]),.DO52(data_out_1[52]),.DO53(data_out_1[53]),.DO54(data_out_1[54]),.DO55(data_out_1[55]),.DO56(data_out_1[56]),
				.DO57(data_out_1[57]),.DO58(data_out_1[58]),.DO59(data_out_1[59]),.DO60(data_out_1[60]),.DO61(data_out_1[61]),.DO62(data_out_1[62]),.DO63(data_out_1[63]),
				.DI0(data_in_1[0]),.DI1(data_in_1[1]),.DI2(data_in_1[2]),.DI3(data_in_1[3]),.DI4(data_in_1[4]),.DI5(data_in_1[5]),.DI6(data_in_1[6]),.DI7(data_in_1[7]),.DI8(data_in_1[8]),
				.DI9(data_in_1[9]),.DI10(data_in_1[10]),.DI11(data_in_1[11]),.DI12(data_in_1[12]),.DI13(data_in_1[13]),.DI14(data_in_1[14]),.DI15(data_in_1[15]),.DI16(data_in_1[16]),
				.DI17(data_in_1[17]),.DI18(data_in_1[18]),.DI19(data_in_1[19]),.DI20(data_in_1[20]),.DI21(data_in_1[21]),.DI22(data_in_1[22]),.DI23(data_in_1[23]),.DI24(data_in_1[24]),
				.DI25(data_in_1[25]),.DI26(data_in_1[26]),.DI27(data_in_1[27]),.DI28(data_in_1[28]),.DI29(data_in_1[29]),.DI30(data_in_1[30]),.DI31(data_in_1[31]),.DI32(data_in_1[32]),
				.DI33(data_in_1[33]),.DI34(data_in_1[34]),.DI35(data_in_1[35]),.DI36(data_in_1[36]),.DI37(data_in_1[37]),.DI38(data_in_1[38]),.DI39(data_in_1[39]),.DI40(data_in_1[40]),
				.DI41(data_in_1[41]),.DI42(data_in_1[42]),.DI43(data_in_1[43]),.DI44(data_in_1[44]),.DI45(data_in_1[45]),.DI46(data_in_1[46]),.DI47(data_in_1[47]),.DI48(data_in_1[48]),
				.DI49(data_in_1[49]),.DI50(data_in_1[50]),.DI51(data_in_1[51]),.DI52(data_in_1[52]),.DI53(data_in_1[53]),.DI54(data_in_1[54]),.DI55(data_in_1[55]),.DI56(data_in_1[56]),
				.DI57(data_in_1[57]),.DI58(data_in_1[58]),.DI59(data_in_1[59]),.DI60(data_in_1[60]),.DI61(data_in_1[61]),.DI62(data_in_1[62]),.DI63(data_in_1[63]),
				.CK(clk),.WEB(write_en_1),.OE(1'b1),.CS(1'b1));
// ===============================================================
//  					SRAM 2
// ===============================================================

Weight_256X64X1BM1  ur_weight(.A0(addr_in_2[0]),.A1(addr_in_2[1]),.A2(addr_in_2[2]),.A3(addr_in_2[3]),.A4(addr_in_2[4]),.A5(addr_in_2[5]),.A6(addr_in_2[6]),.A7(addr_in_2[7]),
				.DO0(data_out_2[0]),.DO1(data_out_2[1]),.DO2(data_out_2[2]),.DO3(data_out_2[3]),.DO4(data_out_2[4]),.DO5(data_out_2[5]),.DO6(data_out_2[6]),.DO7(data_out_2[7]),.DO8(data_out_2[8]),
				.DO9(data_out_2[9]),.DO10(data_out_2[10]),.DO11(data_out_2[11]),.DO12(data_out_2[12]),.DO13(data_out_2[13]),.DO14(data_out_2[14]),.DO15(data_out_2[15]),.DO16(data_out_2[16]),
				.DO17(data_out_2[17]),.DO18(data_out_2[18]),.DO19(data_out_2[19]),.DO20(data_out_2[20]),.DO21(data_out_2[21]),.DO22(data_out_2[22]),.DO23(data_out_2[23]),.DO24(data_out_2[24]),
				.DO25(data_out_2[25]),.DO26(data_out_2[26]),.DO27(data_out_2[27]),.DO28(data_out_2[28]),.DO29(data_out_2[29]),.DO30(data_out_2[30]),.DO31(data_out_2[31]),.DO32(data_out_2[32]),
				.DO33(data_out_2[33]),.DO34(data_out_2[34]),.DO35(data_out_2[35]),.DO36(data_out_2[36]),.DO37(data_out_2[37]),.DO38(data_out_2[38]),.DO39(data_out_2[39]),.DO40(data_out_2[40]),
				.DO41(data_out_2[41]),.DO42(data_out_2[42]),.DO43(data_out_2[43]),.DO44(data_out_2[44]),.DO45(data_out_2[45]),.DO46(data_out_2[46]),.DO47(data_out_2[47]),.DO48(data_out_2[48]),
				.DO49(data_out_2[49]),.DO50(data_out_2[50]),.DO51(data_out_2[51]),.DO52(data_out_2[52]),.DO53(data_out_2[53]),.DO54(data_out_2[54]),.DO55(data_out_2[55]),.DO56(data_out_2[56]),
				.DO57(data_out_2[57]),.DO58(data_out_2[58]),.DO59(data_out_2[59]),.DO60(data_out_2[60]),.DO61(data_out_2[61]),.DO62(data_out_2[62]),.DO63(data_out_2[63]),
				.DI0(data_in_2[0]),.DI1(data_in_2[1]),.DI2(data_in_2[2]),.DI3(data_in_2[3]),.DI4(data_in_2[4]),.DI5(data_in_2[5]),.DI6(data_in_2[6]),.DI7(data_in_2[7]),.DI8(data_in_2[8]),
				.DI9(data_in_2[9]),.DI10(data_in_2[10]),.DI11(data_in_2[11]),.DI12(data_in_2[12]),.DI13(data_in_2[13]),.DI14(data_in_2[14]),.DI15(data_in_2[15]),.DI16(data_in_2[16]),
				.DI17(data_in_2[17]),.DI18(data_in_2[18]),.DI19(data_in_2[19]),.DI20(data_in_2[20]),.DI21(data_in_2[21]),.DI22(data_in_2[22]),.DI23(data_in_2[23]),.DI24(data_in_2[24]),
				.DI25(data_in_2[25]),.DI26(data_in_2[26]),.DI27(data_in_2[27]),.DI28(data_in_2[28]),.DI29(data_in_2[29]),.DI30(data_in_2[30]),.DI31(data_in_2[31]),.DI32(data_in_2[32]),
				.DI33(data_in_2[33]),.DI34(data_in_2[34]),.DI35(data_in_2[35]),.DI36(data_in_2[36]),.DI37(data_in_2[37]),.DI38(data_in_2[38]),.DI39(data_in_2[39]),.DI40(data_in_2[40]),
				.DI41(data_in_2[41]),.DI42(data_in_2[42]),.DI43(data_in_2[43]),.DI44(data_in_2[44]),.DI45(data_in_2[45]),.DI46(data_in_2[46]),.DI47(data_in_2[47]),.DI48(data_in_2[48]),
				.DI49(data_in_2[49]),.DI50(data_in_2[50]),.DI51(data_in_2[51]),.DI52(data_in_2[52]),.DI53(data_in_2[53]),.DI54(data_in_2[54]),.DI55(data_in_2[55]),.DI56(data_in_2[56]),
				.DI57(data_in_2[57]),.DI58(data_in_2[58]),.DI59(data_in_2[59]),.DI60(data_in_2[60]),.DI61(data_in_2[61]),.DI62(data_in_2[62]),.DI63(data_in_2[63]),
				.CK(clk),.WEB(write_en_2),.OE(1'b1),.CS(1'b1));


// ===============================================================
//  					DRAM Interface
// ===============================================================
//parameter
assign arid_m_inf = 0;
assign awid_m_inf = 0;
assign arburst_m_inf = 2'b01;  //INCR
assign awburst_m_inf = 2'b01;  //INCR
assign arlen_m_inf = 127;
assign awlen_m_inf = 127;
assign arsize_m_inf = 3'b100;  // 16* 8Bytes = 128bits
assign awsize_m_inf = 3'b100;  // 16* 8Bytes = 128bits
//read
assign rready_m_inf = 1;      //always 1, wait rvalid handshake to access data;

assign araddr_m_inf = (c_state == STORE_INPUT_WRITE_MAP)? {16'd1,frame_id_reg,11'd0} : (c_state == WRITE_WEIGHT)? {16'd2,frame_id_reg,11'd0} : 0;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)  begin 
		arvalid_m_inf <= 0;
	end
	else if( c_state == IDLE && n_state == STORE_INPUT_WRITE_MAP )begin  //0x0001_0000  --> 0x0001_0800 --> 0x0001_1000
		arvalid_m_inf <= 1;
	end
	else if( c_state == STORE_INPUT_WRITE_MAP && n_state == WRITE_WEIGHT )begin
		arvalid_m_inf <= 1;
	end
	
	else if(arready_m_inf)begin   //address handshake!
		arvalid_m_inf <= 0;
	end
	else begin
		arvalid_m_inf <= arvalid_m_inf;
	end
end
//write
//write address channel
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)  begin
		awvalid_m_inf <= 0; 
		awaddr_m_inf <= 0;
	end
	else if(awready_m_inf) begin
		awvalid_m_inf <= 0;
		awaddr_m_inf <= 0;
	end	
	else if(n_state == WRITE_DRAM && c_state == SOURCE_SINK)begin
		awvalid_m_inf <= 1; 
		awaddr_m_inf <= {16'd1,frame_id_reg,11'd0};
	end

	else begin
		awvalid_m_inf <= awvalid_m_inf;
		awaddr_m_inf <= awaddr_m_inf;
	end
end
//
//use FF block write data 
reg [127:0] data_to_DRAM;
always@(posedge clk ) begin
	if( wready_m_inf  || (awready_m_inf && awvalid_m_inf))begin
		data_to_DRAM <= {data_out_2,data_out_1};
	end

end

assign wdata_m_inf = (wvalid_m_inf)?data_to_DRAM:0;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		wvalid_m_inf <= 0;
	end
	else if(awready_m_inf) begin  //After write address channel  handshake , pull high 
		wvalid_m_inf <= 1;
	end
	else if(wlast_m_inf)begin
		wvalid_m_inf <= 0;
	end
end

assign wlast_m_inf =( cnt_sram_addr == 0)? 1 : 0;
assign bready_m_inf = 1;
//output
always@(posedge clk or  negedge rst_n)begin
	if(!rst_n)  begin
		busy <= 0;
	end
	else if(in_valid)  busy<=0;
	else if(!in_valid && c_state == STORE_INPUT_WRITE_MAP) busy<= 1;
	else if(bvalid_m_inf) busy <= 0;
	else busy <= busy;
end
//cost
reg [3:0] weight_select_reg;
always@(posedge clk) begin
	if(c_state == WRITE_SRAM  && (new_x!=loc_x_end[0] || new_y != loc_y_end[0]) ) weight_select_reg <= weight_select;
	else weight_select_reg <= 0;
end

always@(posedge clk or  negedge rst_n)begin
	if(!rst_n)  begin
		cost <= 0;
	end
	else if(c_state == RETRACE_SRAM_READ )
		cost <= cost + weight_select_reg;
	else if(c_state ==IDLE) cost <= 0;
	else cost <= cost;
end



endmodule


