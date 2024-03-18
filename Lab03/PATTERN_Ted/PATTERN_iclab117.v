`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [13:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;
//================================================================
//   Wires & Registers 
//================================================================
reg read_direct;
reg [13:0] read_addr_dram;
reg [15:0] read_addr_sd;
reg [63:0] Golden_DRAM[0:8191];
reg [63:0] Golden_SD[0:65535];
reg [63:0] golden_ans;

parameter golden_DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
parameter golden_SD_p_r = "../00_TESTBED/SD_init.dat";

real CYCLE = `CYCLE_TIME;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;
integer i,counter;
//integer range_1,range_2;
//////////////////////////////////////////////////////////////////////
// initial block
//////////////////////////////////////////////////////////////////////
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r"); 
    $readmemh(golden_DRAM_p_r,Golden_DRAM);
    $readmemh(golden_SD_p_r,Golden_SD);

    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM); 
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        cal_golden_task;
        wait_out_valid_task;
        check_ans_task;
        repeat(3) @(negedge clk);
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM); //Write down your DRAM Final State
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);		 //Write down your SD CARD Final State
    YOU_PASS_task;
end
//////////////////////////////////////////////////////////////////////
// my task
//////////////////////////////////////////////////////////////////////
task reset_signal_task; begin
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;
    in_valid = 0;
    rst_n = 1;
    force clk = 0;
    #(CYCLE);  rst_n = 0;
    #(CYCLE*2.5);   rst_n = 1;
    if(out_valid !==0||out_data!==0||AW_ADDR!==0||AW_VALID!==0||W_VALID!==0||W_DATA!==0||B_READY!==0||AR_ADDR!==0||AR_VALID!==0||R_READY!==0||MOSI!==1)begin
        $display("SPEC MAIN-1 FAIL");
        $finish;
    end
    #(CYCLE*0.5); release clk;
end endtask
//spec 2 , out_data must = 0 when out_valid = 0;
always@(negedge clk)begin
    if(out_valid == 0 && out_data != 0 &&rst_n ==1 )begin
        $display("SPEC MAIN-2 FAIL");
        $finish;
    end
end
//input task
task input_task;begin
    $fscanf(pat_read, "%d",read_direct);
    $fscanf(pat_read, "%d",read_addr_dram);
    $fscanf(pat_read, "%d",read_addr_sd);
    repeat($urandom_range(2,5))  @(negedge clk);
    in_valid = 1;
    direction = read_direct;
    addr_dram = read_addr_dram;
    addr_sd = read_addr_sd;

    @(negedge clk);
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;
    in_valid = 0;

end endtask
//golden vector
task cal_golden_task;begin
    if(read_direct == 0) begin 
        golden_ans = Golden_DRAM[read_addr_dram];
        Golden_SD[read_addr_sd] = Golden_DRAM[read_addr_dram];
        
    end
    else begin
        golden_ans = Golden_SD[read_addr_sd];
        Golden_DRAM[read_addr_dram] = golden_ans;
        

    end
end
endtask
// wait outvalid && spec 3
task wait_out_valid_task;begin
    latency = 0;
    @(negedge clk);
    while(out_valid !== 1)begin
        latency = latency + 1;
        if(latency == 10000)begin
            $display("SPEC MAIN-3 FAIL");
            $finish;
        end
        @(negedge clk);
    end
end endtask
//check ans
task check_ans_task;begin
    counter = 0;
    while(out_valid)begin
        //range_1 = 63 - 8*counter;
        //range_2 = 56 - 8*counter;

        if(counter == 8 )begin
            $display("SPEC MAIN-4 FAIL");
            $finish;
        end
        if(out_data !== golden_ans[63 - counter*8 -:8])begin
            $display("SPEC MAIN-5 FAIL");
            $finish;
        end
        counter = counter + 1;
        @(negedge clk);
    end
    if(counter != 8)begin
        $display("SPEC MAIN-4 FAIL");
        $finish;
    end
end endtask
//u_dram = golden_dram
always@(*)begin
    if(out_valid ===1)begin
        for(i = 0 ;i<8192;i=i+1)begin
            if(u_DRAM.DRAM[i] !== Golden_DRAM[i]) begin
                $display("SPEC MAIN-6 FAIL");
                $finish;
            end
        end
        for(i = 0 ;i<65536;i=i+1)begin
            if(u_SD.SD[i] !== Golden_SD[i]) begin
                $display("SPEC MAIN-6 FAIL");
                $finish;
            end
        end

    end
end

//////////////////////////////////////////////////////////////////////


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule