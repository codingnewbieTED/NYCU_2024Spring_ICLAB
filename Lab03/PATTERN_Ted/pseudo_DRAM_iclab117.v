//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_DRAM(
	clk, rst_n,
	AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
);

input clk, rst_n;
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output reg AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output reg W_READY;
// write response channel
output reg B_VALID;
output reg [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output reg AR_READY;
// read data channel
output reg [63:0] R_DATA;
output reg R_VALID;
output reg [1:0] R_RESP;
input R_READY;

//================================================================
// parameters & integer
//================================================================
reg [31:0] addr_stored;
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
integer counter,counter_addr_read , counter_rready , counter_rvalid;
integer counter_addr_write;
integer counter_wvalid,counter_wready;
reg [63:0] in_data;
//================================================================
// wire & registers 
//================================================================
reg [63:0] DRAM[0:8191];
initial begin
	$readmemh(DRAM_p_r, DRAM);
	//read addr
	AR_READY = 0;
	//read data
	R_DATA = 64'd0;
	R_VALID = 0;
	R_RESP = 2'd00;
	//write addr
	AW_READY = 0;
	//write data
	W_READY = 0;
	//write response
	B_RESP = 2'b00;
	B_VALID = 0;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
always@(negedge clk)begin
	if( (AR_VALID ===0 && AR_ADDR !== 0 && rst_n ==1) || (AW_VALID ===0 && AW_ADDR !== 0 && rst_n ==1) ||(W_VALID === 0 && W_DATA !== 0 && rst_n ==1) ) begin
		$display("SPEC DRAM-1 FAIL");
		repeat(2) @(posedge clk);
		$finish;
	end
end

always@(negedge clk)begin
	if( (R_READY ===1 && (AR_READY===1 || AR_VALID===1)  && rst_n ==1 ) || (W_VALID ===1 && (AW_READY===1 || AW_VALID ===1) && rst_n ==1))begin
		$display("SPEC DRAM-5 FAIL");
		$finish;
	end
end

always@(*)begin
	if(AR_VALID)begin
		addr_check;
		read_addr_channel;
		R_ready_check;
	end
	if(AW_VALID)begin
		addr_check;
		write_addr_channel;
		write_data_channel;
		write_response;
	end
end

task addr_check;begin
	if(AR_VALID)  addr_stored = AR_ADDR;
	else if(AW_VALID)          addr_stored = AW_ADDR;
	else addr_stored = addr_stored;
	
	if(addr_stored >8191)begin      //????????? <0  ???
		$display("SPEC DRAM-2 FAIL");
		$finish;
	end
end endtask

task read_addr_channel;begin
	counter = 0;
	counter_addr_read = $urandom_range(2,50);
	while(counter <= counter_addr_read + 1)begin
		if(AR_ADDR!= addr_stored || AR_VALID != 1) begin   //remain stable before AR_READY
			$display("SPEC DRAM-3 FAIL");
			$finish;
		end
		if(counter == counter_addr_read) AR_READY = 1;
		else AR_READY = 0;
		counter = counter + 1;
		@(posedge clk);
	end
	//AR_READY = 0;
end endtask


task R_ready_check;begin
	counter = 0;
	counter_rready = 0;
	counter_rvalid = $urandom_range(1,90);

	while(R_READY == 0)begin
		if(counter_rready == 100)begin
			$display("SPEC DRAM-4 FAIL");
			$finish;
		end
		
		if(counter_rready == counter_rvalid)begin
			R_VALID = 1;
			R_DATA = DRAM[addr_stored];
			R_RESP = 2'b00;
		end

		counter_rready = counter_rready + 1;
		@(posedge clk);
	end
	/*
	if(counter_rready > counter_rvalid)begin
		R_VALID = 1;
		R_DATA = DRAM[addr_stored];
		R_RESP = 2'b00;
		//@(posedge clk);
	end*/
	if(counter_rready <= counter_rvalid) begin
		while(counter_rready <= counter_rvalid + 1)begin
			if(R_READY != 1)begin
				$display("SPEC DRAM-3 FAIL");
				$finish;
			end
			if(counter_rready == counter_rvalid) begin
				R_VALID = 1;
				R_DATA = DRAM[addr_stored];
				R_RESP = 2'b00;
			end
			else begin
				R_VALID = 0;
				R_DATA = 64'b0;
				R_RESP = 2'b00;
			end
			counter_rready = counter_rready +1;
			@(posedge clk);
		end
	end
	R_VALID = 0;
	R_DATA = 64'b0;
	R_RESP = 2'b00;
end endtask
//////////////////////////////////////////////////////////////////////
// DRAM Write 
//////////////////////////////////////////////////////////////////////
task write_addr_channel;begin
	counter = 0;
	counter_addr_write = $urandom_range(2,50);
	while(counter <= counter_addr_write + 1)begin
		if(AW_ADDR!= addr_stored || AW_VALID != 1) begin   //remain stable before AR_READY
			$display("SPEC DRAM-3 FAIL");
			$finish;
		end
		if(counter == counter_addr_write) AW_READY = 1;
		else AW_READY = 0;
		counter = counter + 1;
		@(posedge clk);
	end
	AR_READY = 0;
end endtask


task write_data_channel;begin
	//counter = 0;
	counter_wvalid = 0;
	counter_wready = $urandom_range(1,90);

	while(W_VALID == 0)begin
		if(counter_wvalid == 100)begin
			$display("SPEC DRAM-4 FAIL");
			$finish;
		end
		
		if(counter_wvalid == counter_wready)begin
			W_READY = 1;
		end

		counter_wvalid = counter_wvalid + 1;
		@(posedge clk);
	end
	
	if(counter_wvalid > counter_wready)begin
		W_READY = 1;
		in_data = W_DATA;
		//@(posedge clk);
	end
	else begin
		in_data = W_DATA;
		while(counter_wvalid <= counter_wready + 1)begin
			if(W_VALID != 1 || W_DATA != in_data)begin
				$display("SPEC DRAM-3 FAIL");
				$finish;
			end
			if(counter_wvalid == counter_wready) begin
				W_READY = 1;
			end
			else begin
				W_READY = 0;
			end
			counter_wvalid = counter_wvalid +1;
			@(posedge clk);
		end
	end
	W_READY = 0;

end endtask

task write_response;begin
	counter = 0;
	B_RESP = 2'b00;
	B_VALID = 1;
	while(B_READY == 0)begin
		if(counter == 100)begin
			$display("SPEC DRAM-4 FAIL");
			$finish;
		end
		counter = counter+1;
		@(posedge clk);
	end
	DRAM[addr_stored] = in_data;
	@(posedge clk);
	B_RESP = 2'b00;
	B_VALID = 0;
end endtask


//////////////////////////////////////////////////////////////////////

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask

endmodule
