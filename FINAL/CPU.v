//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 //synopsys translate_off
`include "/RAID2/cad/synopsys/synthesis/2022.03/dw/sim_ver/DW_mult_pipe.v"
`include "/RAID2/cad/synopsys/synthesis/2022.03/dw/sim_ver/DW02_mult_4_stage.v"
`include "/RAID2/cad/synopsys/synthesis/2022.03/dw/sim_ver/DW02_mult_2_stage.v"
//synopsys translate_on
module CPU(

clk,
rst_n,

IO_stall,

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
bready_m_inf,
            
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
rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
There are sixteen registers in your CPU. You should not change the name of those registers.
TA will check the value in each register when your core is not busy.
If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
reg [3:0] c_state,n_state;
parameter SRAM_instr = 'd0, IF = 'd1, ID = 'd2, EXE1 = 'd3, LOAD = 'd4, STORE = 'd5, SRAM_data = 'd6, INIT = 'd7
          ,IDLE = 'd8, WB = 'd9, EXE2 = 'd10;
reg [15:0] instruction;
//reg [1:0] instr_type;
//parameter R_instr = 2'b00, I_st_ld = 2'b01, I_beq= 2'b10, M_instr = 2'b11;
//refresh sram
wire instr_cache_miss, data_cache_miss;
reg branch_take;   
reg SRAM_instr_init, SRAM_data_init;
wire SRAM_init;   
reg [10:0] cnt_pc,cnt_data;
wire [3:0] rs,rt,rd;
wire signed[4:0] immediate;
wire [4:0] coeff_a;
wire [8:0] coeff_b;
//cnt
//sram
wire[15:0] sram_instr_out, sram_data_out;
reg [15:0] data_out_reg;
//ALU
//decode
reg signed[15:0] ALU_in1, ALU_in2, a,b;
reg signed[15:0] ALU_out_reg;
//EXE
wire [10:0] addr_load;  //2048 entry
wire signed[16:0] add_out;
wire [15:0] mult_out;
wire less_out;
//determinant
wire signed[68:0] det_out , shift1,shift2;
wire flag_determinant;
reg [15:0] n_output;
//####################################################
//              FSN
//####################################################
always@(posedge clk or negedge rst_n)begin
if(!rst_n) c_state <= INIT;
else c_state <= n_state;
end

always@(*)begin
  case(c_state)
  IDLE: n_state = INIT;
  IF:begin
    if(instr_cache_miss) n_state = SRAM_instr;
    else n_state = ID;
  end
  ID:begin
    //if(instruction[15:14] == 2'b10) n_state = IF;   //beq
     n_state = EXE1;
  end
  EXE1: begin
    if(instruction[15:14] == 2'b10) n_state = IF;      //beq
    else if(instruction[15:13]== 3'b011) n_state = STORE;
    else if(instruction[15:13]== 3'b010)n_state = LOAD;
    else if((instruction[13] && instruction[0]) || (instruction[15] && instruction[14]))n_state = EXE2;   //Rtype && Mtype
    else n_state = WB;
  end
  EXE2: begin 
    if(instruction[15])begin
      if(flag_determinant) n_state = WB;
      else n_state = EXE2;
    end
    else n_state = WB;
  end
  WB: begin 
    //if(instr_cache_miss) n_state = SRAM_instr;  
    //else n_state = IF;
    n_state = IF;
  end
  LOAD:begin
    if(data_cache_miss) n_state = SRAM_data;
    else n_state = WB;
  end

  STORE:begin
    if(bvalid_m_inf) begin
      //if(instr_cache_miss) n_state = SRAM_instr;
      //else
       n_state = IF;
    end
    else n_state = STORE;
  end
  SRAM_instr: begin
    if(SRAM_instr_init) n_state = IF;
    else n_state = SRAM_instr;
  end

  SRAM_data: begin
    if(SRAM_data_init) n_state = LOAD;
    else n_state = SRAM_data;
  end

  INIT:begin
    if(SRAM_init) n_state = IF;
    else n_state = INIT;
  end
  default: n_state = IF;

endcase end
//####################################################
//              signal
//####################################################
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) instruction <= 0;
  else if(n_state == ID) instruction <= sram_instr_out;
end
/*
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    SRAM_instr_init <= 0;
    SRAM_data_init <= 0;
  end
  else begin
    SRAM_instr_init <= rlast_m_inf[1];
    SRAM_data_init <= rlast_m_inf[0];
  end
end*/

assign SRAM_init = SRAM_instr_init & SRAM_data_init;

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    SRAM_instr_init <= 0;
  end
  else if(rlast_m_inf[1]) SRAM_instr_init <= 1;
  else if(c_state == IF) SRAM_instr_init <= 0;
end

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    SRAM_data_init <= 0;
  end
  else if(rlast_m_inf[0]) SRAM_data_init <= 1;
  else if(c_state == LOAD) SRAM_data_init <= 0;
end

//opcode
assign rs = instruction[12:9];
assign rt = instruction[8:5];
assign rd = instruction[4:1];
assign immediate = instruction[4:0];
assign coeff_a = instruction[12:9];
assign coeff_b = instruction[8:0];
//catche miss
reg [3:0] instr_page, data_page;
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    instr_page <= 0;
    data_page <= 0;
  end
  else if(c_state == SRAM_instr) instr_page <= cnt_pc[10:7];
  else if(c_state == SRAM_data) data_page <= cnt_data[10:7];
end

assign instr_cache_miss = (instr_page != cnt_pc[10:7]);
assign data_cache_miss  = (data_page  != cnt_data[10:7]);

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) branch_take <= 0;
  else if(c_state == ID && (a == b) && instruction[15:14] == 2'b10) branch_take <= 1;
  else branch_take <= 0;
end

//####################################################
//             ALU
//####################################################

//-------------------------
//     instr-decode
//-------------------------
always@(posedge clk)begin
  ALU_in1 <= (instruction[15:14] == 2'b10)? cnt_pc : a;   //  reg[rs] && pc_counter for branch 
end

always@(posedge clk)begin
  if(instruction[15:14] == 2'b00) begin
    if( instruction[13] ^ instruction[0] ) ALU_in2 <= -b; //  reg[rt] && immediate for I type
    else ALU_in2 <= b;
  end
  else ALU_in2 <= immediate;
end

always@(*) begin
  case (rs)
    4'd0:  a = core_r0;
    4'd1:  a = core_r1;
    4'd2:  a = core_r2;
    4'd3:  a = core_r3;
    4'd4:  a = core_r4;
    4'd5:  a = core_r5;
    4'd6:  a = core_r6;
    4'd7:  a = core_r7;
    4'd8:  a = core_r8;
    4'd9:  a = core_r9;
    4'd10: a = core_r10;
    4'd11: a = core_r11;
    4'd12: a = core_r12;
    4'd13: a = core_r13;
    4'd14: a = core_r14;
    4'd15: a = core_r15;
  endcase
end

always@(*) begin
  case (rt)
    4'd0:  b = core_r0;
    4'd1:  b = core_r1;
    4'd2:  b = core_r2;
    4'd3:  b = core_r3;
    4'd4:  b = core_r4;
    4'd5:  b = core_r5;
    4'd6:  b = core_r6;
    4'd7:  b = core_r7;
    4'd8:  b = core_r8;
    4'd9:  b = core_r9;
    4'd10: b = core_r10;
    4'd11: b = core_r11;
    4'd12: b = core_r12;
    4'd13: b = core_r13;
    4'd14: b = core_r14;
    4'd15: b = core_r15;
  endcase
end
//-------------------------
//     execution
//-------------------------
wire [31:0] mult;
reg signed [68:0] shift_reg; 
//--------------
//  add & mult
//--------------
assign add_out = ALU_in1 + ALU_in2;
//assign mult_out = ALU_in1 * ALU_in2;

DW_mult_pipe #(16,16,2,0,0,1) U5
  (.clk(clk),
  .rst_n(rst_n),
  .en(1'b0),
  .tc(1'b1),
  .a(ALU_in1),
  .b(ALU_in2),
  .product(mult) );
assign mult_out = mult[15:0];
assign addr_load = add_out[10:0];
assign less_out = (add_out[16])? 1'b1 : 1'b0;
//reg
always@(posedge clk) begin
  if(instruction[14:13] == 2'b01)begin
    if(instruction[0]) ALU_out_reg <= mult_out;
    else ALU_out_reg <= less_out;
  end
  else ALU_out_reg <= add_out;
end
//--------------
// determinant4X4
//--------------
determinant_4X4 my_4X4(.clk(clk),.rst_n(rst_n),.en(c_state == IF),.r0(core_r0),.r1(core_r1),.r2(core_r2),.r3(core_r3),.r4(core_r4),.r5(core_r5),.r6(core_r6),.r7(core_r7),.r8(core_r8),
.r9(core_r9),.r10(core_r10),.r11(core_r11),.r12(core_r12),.r13(core_r13),.r14(core_r14),.r15(core_r15),.out_valid(flag_determinant),.out_data(det_out));

assign shift1 = det_out >>> {coeff_a,1'b0};
assign shift2 = shift1 >>> coeff_b;

always@(posedge clk) begin
  shift_reg <= shift2;
end

	always@(*)begin
		if(shift_reg[68] && ~&shift_reg[67:16])  n_output = -32768;     //  1000_0000_0000_0000 shift_reg < -32768
		else if(!shift_reg[68] && |shift_reg[67:16]) n_output = 32767;   //  0111_1111_1111_1111  shift_reg > 32767
		else n_output = shift_reg;
	end
//####################################################
//             REG , output
//####################################################

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    core_r0 <= 0;
    core_r1 <= 0;
    core_r2 <= 0;
    core_r3 <= 0;
    core_r4 <= 0;
    core_r5 <= 0;
    core_r6 <= 0;
    core_r7 <= 0;
    core_r8 <= 0;
    core_r9 <= 0;
    core_r10 <= 0;
    core_r11 <= 0;
    core_r12 <= 0;
    core_r13 <= 0;
    core_r14 <= 0;
    core_r15 <= 0;
  end
  else if(c_state == WB) begin
    if(instruction[15]) core_r0 <= n_output;   //determinant
    else if(instruction[14])begin              //I type:load
      case (rt)
      4'd0:  core_r0 <= data_out_reg;
      4'd1:  core_r1 <= data_out_reg;
      4'd2:  core_r2 <= data_out_reg;
      4'd3:  core_r3 <= data_out_reg;
      4'd4:  core_r4 <= data_out_reg;
      4'd5:  core_r5 <= data_out_reg;
      4'd6:  core_r6 <= data_out_reg;
      4'd7:  core_r7 <= data_out_reg;
      4'd8:  core_r8 <= data_out_reg;
      4'd9:  core_r9 <= data_out_reg;
      4'd10: core_r10 <= data_out_reg;
      4'd11: core_r11 <= data_out_reg;
      4'd12: core_r12 <= data_out_reg;
      4'd13: core_r13 <= data_out_reg;
      4'd14: core_r14 <= data_out_reg;
      4'd15: core_r15 <= data_out_reg;
      endcase
  end
  else begin
      case (rd)                                //Rtype WB
      4'd0:  core_r0 <= ALU_out_reg;
      4'd1:  core_r1 <= ALU_out_reg;
      4'd2:  core_r2 <= ALU_out_reg;
      4'd3:  core_r3 <= ALU_out_reg;
      4'd4:  core_r4 <= ALU_out_reg;
      4'd5:  core_r5 <= ALU_out_reg;
      4'd6:  core_r6 <= ALU_out_reg;
      4'd7:  core_r7 <= ALU_out_reg;
      4'd8:  core_r8 <= ALU_out_reg;
      4'd9:  core_r9 <= ALU_out_reg;
      4'd10: core_r10 <= ALU_out_reg;
      4'd11: core_r11 <= ALU_out_reg;
      4'd12: core_r12 <= ALU_out_reg;
      4'd13: core_r13 <= ALU_out_reg;
      4'd14: core_r14 <= ALU_out_reg;
      4'd15: core_r15 <= ALU_out_reg;
      endcase
    end
  end
end

always@(posedge clk or  negedge rst_n)begin
  if(!rst_n) IO_stall <= 1;
  else if(n_state == IF && (c_state != INIT) && (c_state != SRAM_instr)) IO_stall <= 0;
  else IO_stall <= 1;
end
//####################################################
//             AXI DRAM
//####################################################
reg flag_addr_instr, flag_addr_data;
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    cnt_pc <= 0;
  end
  else if(n_state == ID) cnt_pc <= cnt_pc + 1;
  //else if(instruction[15:13] == 3'b101 ) cnt_pc <= instruction[12:1];  //jump
  else if(branch_take) cnt_pc <= addr_load;
end

always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    cnt_data <= 0;
  end
  else if(n_state == LOAD) cnt_data <= addr_load;
end
//-------------------------
//             AXI READ
//-------------------------
//read addr channel
assign arvalid_m_inf[1] = (c_state == INIT || c_state == SRAM_instr)? flag_addr_instr:0;
assign arvalid_m_inf[0] = (c_state == INIT || c_state == SRAM_data)? flag_addr_data:0;
assign araddr_m_inf[63:32] = {20'h00001,cnt_pc[10:7],7'b0,1'b0}; //offset, cache page , 128 entry, byte offset
assign araddr_m_inf [31:0] = {20'h00001,cnt_data[10:7],7'b0,1'b0};

assign arid_m_inf[7:0]    = 0;
assign arburst_m_inf[3:0] = 4'b01_01;
assign arsize_m_inf[5:0]  = 6'b001_001;
assign arlen_m_inf[13:0]   = 14'b1111111_1111111;

//read data channel
assign rready_m_inf = 2'b11;

//flag addr_valid control
//instr arvalid
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) flag_addr_instr <= 1;
  else if(arready_m_inf[1]) flag_addr_instr <= 0;
  else if(c_state == IF)  flag_addr_instr <= 1;
end
//data arvalid
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) flag_addr_data <= 1;
  else if(arready_m_inf[0]) flag_addr_data <= 0;
  else if(c_state == LOAD)  flag_addr_data <= 1;
end
//-------------------------
//             AXI WRITE
//-------------------------
reg flag_write_addr, flag_write_data;
reg [15:0] b_reg;
//write addr channel
assign awvalid_m_inf = (c_state == STORE)? flag_write_addr:0;
assign awaddr_m_inf = {20'h00001,ALU_out_reg[10:0],1'b0};//{20'h00001,addr_load,1'b0};

assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b001;
assign awlen_m_inf = 0;
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) flag_write_addr <= 1;
  else if(awready_m_inf) flag_write_addr <= 0;
  else if(c_state == EXE1) flag_write_addr <= 1;
end
//write data channel
always@(posedge clk )begin
  b_reg <= b;
end
assign wvalid_m_inf = flag_write_data;
assign wlast_m_inf  = flag_write_data;
assign wdata_m_inf  = b_reg ;
always@(posedge clk or negedge rst_n)begin
  if(!rst_n) flag_write_data <= 0;
  else if(awready_m_inf) flag_write_data <= 1;
  else if(wready_m_inf)  flag_write_data <= 0;
end
//write response channel
assign bready_m_inf = 1;
//####################################################
//             SRAM
//####################################################
reg [6:0] cnt_sram_instr, cnt_sram_data;
reg [6:0] addr_sram_instr;
wire [6:0] addr_sram_data;
wire [15:0] data_in;
wire [15:0] data_in_instr;

//assign addr_sram_instr = (rvalid_m_inf[1])? cnt_sram_instr[6:0] : (branch_take)? addr_load[6:0] : cnt_pc[6:0];  //addr_load : branch target
always@(*)begin
  if(rvalid_m_inf[1]) addr_sram_instr = cnt_sram_instr[6:0];
  //else if(instruction[15:13] == 3'b101) addr_sram_instr = instruction[12:1];  //jump
  else if(branch_take) addr_sram_instr = addr_load[6:0];
  else addr_sram_instr = cnt_pc[6:0];
end

assign addr_sram_data  = (rvalid_m_inf[0])? cnt_sram_data[6:0]  : addr_load[6:0];

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) cnt_sram_instr <= 0;
  else if(rvalid_m_inf[1]) cnt_sram_instr <= cnt_sram_instr + 1;
end

always@(posedge clk or negedge rst_n)begin
  if(!rst_n) cnt_sram_data <= 0;
  else if(rvalid_m_inf[0]) cnt_sram_data <= cnt_sram_data + 1;
end
//directly input DRAM to SRAM will have violation(because pattern of DRAM change at posedge clk)
//debug
assign data_in_instr = (rvalid_m_inf)?rdata_m_inf[31:16]:0;  

wire wen_instr, wen_data;
assign wen_instr = (c_state == SRAM_instr || c_state == INIT)? rvalid_m_inf[1] : 0;
assign wen_data = (c_state == SRAM_data  ||  c_state == INIT)? rvalid_m_inf[0] : 0;
SUMA180_128X16X1BM1  instr_cache  
(.A0(addr_sram_instr[0]), .A1(addr_sram_instr[1]), .A2(addr_sram_instr[2]), .A3(addr_sram_instr[3]), .A4(addr_sram_instr[4]), .A5(addr_sram_instr[5]), .A6(addr_sram_instr[6]),
.DO0(sram_instr_out[0]), .DO1(sram_instr_out[1]), .DO2(sram_instr_out[2]), .DO3(sram_instr_out[3]), .DO4(sram_instr_out[4]), .DO5(sram_instr_out[5]), .DO6(sram_instr_out[6]), .DO7(sram_instr_out[7]), 
.DO8(sram_instr_out[8]), .DO9(sram_instr_out[9]), .DO10(sram_instr_out[10]), .DO11(sram_instr_out[11]), .DO12(sram_instr_out[12]), .DO13(sram_instr_out[13]), .DO14(sram_instr_out[14]), .DO15(sram_instr_out[15]),
.DI0(data_in_instr[0]), .DI1(data_in_instr[1]), .DI2(data_in_instr[2]), .DI3(data_in_instr[3]), .DI4(data_in_instr[4]), .DI5(data_in_instr[5]), .DI6(data_in_instr[6]), .DI7(data_in_instr[7]), 
.DI8(data_in_instr[8]), .DI9(data_in_instr[9]), .DI10(data_in_instr[10]), .DI11(data_in_instr[11]), .DI12(data_in_instr[12]), .DI13(data_in_instr[13]), .DI14(data_in_instr[14]), .DI15(data_in_instr[15]),
 .CK(clk), .WEB( ~wen_instr ), .OE(1'b1), .CS(1'b1));


 assign data_in = (c_state == STORE)? b  : rdata_m_inf[15:0];

 SUMA180_128X16X1BM1  data_cache
 (.A0(addr_sram_data[0]), .A1(addr_sram_data[1]), .A2(addr_sram_data[2]), .A3(addr_sram_data[3]), .A4(addr_sram_data[4]), .A5(addr_sram_data[5]), .A6(addr_sram_data[6]),
 .DO0(sram_data_out[0]), .DO1(sram_data_out[1]), .DO2(sram_data_out[2]), .DO3(sram_data_out[3]), .DO4(sram_data_out[4]), .DO5(sram_data_out[5]), .DO6(sram_data_out[6]), .DO7(sram_data_out[7]), 
 .DO8(sram_data_out[8]), .DO9(sram_data_out[9]), .DO10(sram_data_out[10]), .DO11(sram_data_out[11]), .DO12(sram_data_out[12]), .DO13(sram_data_out[13]), .DO14(sram_data_out[14]), .DO15(sram_data_out[15]),
 .DI0(data_in[0]), .DI1(data_in[1]), .DI2(data_in[2]), .DI3(data_in[3]), .DI4(data_in[4]), .DI5(data_in[5]), .DI6(data_in[6]), .DI7(data_in[7]), 
 .DI8(data_in[8]), .DI9(data_in[9]), .DI10(data_in[10]), .DI11(data_in[11]), .DI12(data_in[12]), .DI13(data_in[13]), .DI14(data_in[14]), .DI15(data_in[15]),
  .CK(clk), .WEB( ~ (wen_data || (c_state == STORE && data_page == addr_load[10:7]) )), .OE(1'b1), .CS(1'b1));


  always@(posedge clk) data_out_reg <= sram_data_out;
endmodule

//####################################################
//             SUBMODULE
//####################################################
module determinant_4X4(clk,rst_n,en,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,out_valid,out_data);
	input clk,en,rst_n; 
	input [15:0] r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15;
	output reg [68:0] out_data;
	output reg out_valid;
	//####################################################
	//              wire
	//####################################################
	reg [15:0] d1,d2,d3,d4,d5,d6,d7,d8;
	reg [4:0] cnt_exe;
	wire signed[32:0] d_out1,d_out2;
	wire signed[65:0] mult_out;
	reg signed[65:0] mult_out_reg;
	reg signed[68:0] sum_reg;
	wire signed[68:0] sum_out;
	//####################################################
	//              design
	//####################################################
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			cnt_exe <= 0;
		end
		else if(en) cnt_exe <= 1;
		else if(|cnt_exe) cnt_exe <= cnt_exe + 1;
	end
	always@(*)begin
		case (cnt_exe[2:0])
		3'd1,3'd3:d1=r0;
		3'd2,3'd6:d1=r2;
		3'd4:d1=r1;
		3'd5:d1=r3;
		default:d1=0;
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d2 = r5;
		3'd2 : d2 = r4;
		3'd3 : d2 = r7;
		3'd4 : d2 = r6;
		3'd5 : d2 = r5;
		3'd6 : d2 = r7;
		default: d2 = 0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d3 = r1;
		3'd2 : d3 = r0;
		3'd3 : d3 = r3;
		3'd4 : d3 = r2;
		3'd5 : d3 = r1;
		3'd6 : d3 = r3;
		default: d3 = 0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d4 = r4;
		3'd2 : d4 = r6;
		3'd3 : d4 = r4;
		3'd4 : d4 = r5;
		3'd5 : d4 = r7;
		3'd6 : d4 = r6;
		default: d4 = 0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d5 = r10;
		3'd2 : d5 = r9;
		3'd3 : d5 = r9;
		3'd4 : d5 = r8;
		3'd5 : d5 = r8;
		3'd6 : d5 = r8;
		default: d5 =0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d6 = r15;
		3'd2 : d6 = r15;
		3'd3 : d6 = r14;
		3'd4 : d6 = r15;
		3'd5 : d6 = r14;
		3'd6 : d6 = r13;
		default: d6 = 0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d7 = r11;
		3'd2 : d7 = r11;
		3'd3 : d7 = r10;
		3'd4 : d7 = r11;
		3'd5 : d7 = r10;
		3'd6 : d7 = r9;
		default: d7 = 0; 
		endcase
	end

	always@(*)begin
		case (cnt_exe[2:0])
		3'd1 : d8 = r14;
		3'd2 : d8 = r13;
		3'd3 : d8 = r13;
		3'd4 : d8 = r12;
		3'd5 : d8 = r12;
		3'd6 : d8 = r12;
		default: d8 = 0; 
		endcase
	end
	reg [15:0] d1_reg,d2_reg,d3_reg,d4_reg,d5_reg,d6_reg,d7_reg,d8_reg;
	always@(posedge clk)begin
		d1_reg <= d1;
		d2_reg <= d2;
		d3_reg <= d3;
		d4_reg <= d4;
		d5_reg <= d5;
		d6_reg <= d6;
		d7_reg <= d7;
		d8_reg <= d8;
	end

	determinant_2X2 u1_det_2X2(.clk(clk),.a(d1_reg),.b(d2_reg),.c(d3_reg),.d(d4_reg),.out_value(d_out1));
	determinant_2X2 u2_det_2X2(.clk(clk),.a(d5_reg),.b(d6_reg),.c(d7_reg),.d(d8_reg),.out_value(d_out2));

	always@(posedge clk) mult_out_reg <=mult_out; // d_out1 * d_out2;
	/*
	DW_mult_pipe #(33, 33, 4,0, 0, 1) U3
		(.clk(clk),
		.rst_n(rst_n),
		.en(1'b0),
		.tc(1'b1),
		.a(d_out1),
		.b(d_out2),
		.product(mult_out) );*/
    DW02_mult_4_stage #(33, 33)
		U77 ( .A(d_out1),
		.B(d_out2),
		.TC(1'b1),
		.CLK(clk),
		.PRODUCT(mult_out) );
	assign sum_out = mult_out_reg + sum_reg;

	always@(posedge clk or negedge rst_n)begin
		if(!rst_n) sum_reg <= 0;
		else if(cnt_exe >= 9) sum_reg <= sum_out;
		else sum_reg <= 0;
	end

	//output
  //always@(*)  out_valid = (cnt_exe == 16);
  
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			out_valid <= 0;
		end
		else if(cnt_exe == 14) begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
  always@(posedge clk)begin
    out_data <= sum_out;
  end
endmodule


module determinant_2X2(clk,a,b,c,d,out_value);
	input clk;
	input signed [15:0] a,b,c,d;
	output reg signed[32:0] out_value;

	wire signed [31:0] m1,m2;
	reg signed [31:0] m1_reg,m2_reg;
	wire signed [32:0] minus;


  DW_mult_pipe #(16, 16, 2,0, 0, 1) U4
		(.clk(clk),
		.rst_n(rst_n),
		.en(1'b0),
		.tc(1'b1),
		.a(a),
		.b(b),
		.product(m1) );

	DW_mult_pipe #(16, 16, 2,0, 0, 1) U5
		(.clk(clk),
		.rst_n(rst_n),
		.en(1'b0),
		.tc(1'b1),
		.a(c),
		.b(d),
		.product(m2) );
	//assign m1 = a * b;
	//assign m2 = c * d;
	assign minus = m1_reg - m2_reg;

	always@(posedge clk)begin
		m1_reg <= m1;
		m2_reg <= m2;
		out_value <= minus;
	end
endmodule





















