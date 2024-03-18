//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
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

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE=4'd0;
parameter direction_choice=4'd1;
parameter DRAM_read_addr_channel=4'd2;
parameter DRAM_read_data_channel=4'd3;
parameter SD_command=4'd4;
parameter wait_response=4'd5;
parameter wait_8_cycle = 4'd6;
parameter SD_data_in=4'd7;
parameter SD_response = 4'd8;
parameter busy = 4'd9;
parameter out_stage = 4'd10;
//SD read
parameter SD_read_out=4'd11;
parameter DRAM_write_addr_channel = 4'd12;
parameter DRAM_write_data_channel = 4'd13;
parameter DRAM_write_response_channel = 4'd14;

integer i;
//==============================================//
//           reg & wire declaration             //
//==============================================//
//universal
reg direct_stored ;
reg [12:0] addr_dram_stored;
reg [15:0] addr_sd_stored;
reg [3:0] c_state,n_state;
wire [47:0]SD_addr_command;
//direction0
wire [87:0]SD_data_block;
reg [63:0] data_fromDRAM;
wire [6:0] CRC_7 ;
wire [15:0] CRC_16;
reg [7:0] SD_response_reg;
reg [5:0] cnt_SD_command;
reg [3:0] cnt_response;
reg [3:0] cnt_wait;
reg [6:0] cnt_SD_block;  // 0~88
//direction1
reg flag_SD_read;
reg [63:0] data_fromSD;
reg [6:0] cnt_SD_read ;
//out
wire [63:0] ans;
reg [3:0] cnt_out;
//==============================================//
//                  design                      //
//==============================================//

//==============================================//
//                     FSM                      //
//==============================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) c_state <= IDLE;
    else c_state <= n_state;
end

always@(*)begin
    case (c_state)
        IDLE:begin
            if(in_valid) n_state = direction_choice;
            else n_state = IDLE;
        end 
        direction_choice:begin
            if(direct_stored) n_state = SD_command;//SD_read;
            else n_state = DRAM_read_addr_channel;
        end
        DRAM_read_addr_channel:begin
            if(AR_VALID && AR_READY) n_state = DRAM_read_data_channel;
            else n_state = DRAM_read_addr_channel;
        end
        DRAM_read_data_channel:begin
            if(R_READY && R_VALID)  n_state = SD_command;
            else n_state = DRAM_read_data_channel;
        end
        SD_command:begin
            if(cnt_SD_command == 48)  n_state = wait_response;
            else n_state = SD_command;
        end
        wait_response:begin
            if(cnt_response == 8 && !direct_stored) n_state = wait_8_cycle;
            else if(cnt_response == 8 && direct_stored) n_state = SD_read_out;
            else n_state = wait_response;
        end
        wait_8_cycle:begin      //wait 8 cycle before SD_data sent in  
            if(cnt_wait == 7 ) n_state = SD_data_in;
            //else if(cnt_wait ==8 && direct_stored ==1) n_state = SD_data_out;
            else n_state = wait_8_cycle;
        end
        SD_data_in:begin
            if(cnt_SD_block == 88) n_state = SD_response;
            else n_state = SD_data_in;
        end
        SD_response:begin
            if(SD_response_reg == 8'b00000101) n_state = busy;
            else n_state = SD_response;
        end
        busy:begin
            if(MISO == 1) n_state = out_stage;
            else n_state = busy;
        end
        //read SD to write DRAM 
        SD_read_out:begin
            if(cnt_SD_read == 64) n_state = DRAM_write_addr_channel;
            else n_state = SD_read_out;
        end
        DRAM_write_addr_channel:begin
            if(AW_VALID && AW_READY) n_state = DRAM_write_data_channel;
            else n_state = DRAM_write_addr_channel;
        end
        DRAM_write_data_channel:begin
            if(W_READY && W_VALID)  n_state = DRAM_write_response_channel ;
            else n_state = DRAM_write_data_channel;
        end
        DRAM_write_response_channel:begin
            if(B_READY && B_VALID)  n_state = out_stage;
            else n_state = DRAM_write_response_channel;
        end
        //out_stage
        out_stage:begin
            if(cnt_out == 8) n_state = IDLE;
            else n_state = out_stage;
        end
        default: n_state = IDLE;
    endcase
end
//==============================================//
//                   output                     //
//==============================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_out <= 0;
    else if(n_state == out_stage) cnt_out <= cnt_out + 1;
    else cnt_out <= 0;
end


assign ans = (direct_stored)?data_fromSD:data_fromDRAM;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 0;
        out_data <= 0;
    end
    else if(n_state == out_stage) begin
        out_valid <= 1;
        out_data <= ans[63- cnt_out*8 -:8];  // golden_ans[63 - counter*8 -:8]
    end
    else begin
        out_valid <= 0;
        out_data <= 0;
    end
end


//==============================================//
//     direction=1:SD read to DRAM write        //
//==============================================//
//B_ready
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) B_READY <= 0;
    else if(n_state == DRAM_write_response_channel || n_state == DRAM_write_data_channel)  B_READY <= 1;
    else B_READY <= 0;
end
//DRAM write data channel
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        W_VALID <= 0;
        W_DATA <= 0;
    end
    else if(n_state == DRAM_write_data_channel)begin
        W_VALID <= 1;
        W_DATA <= data_fromSD;
    end
    else begin
        W_VALID <= 0;
        W_DATA <= 0;
    end
end

//DRAM write addr channel
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AW_ADDR <= 0;
        AW_VALID <= 0;
    end
    else if(n_state == DRAM_write_addr_channel)begin
        AW_ADDR <= addr_dram_stored;
        AW_VALID <= 1;
    end
    else begin
        AW_ADDR <= 0;
        AW_VALID <= 0;
    end
end


/////////////////////SD_read_out  cnt/flag/data
//reg flag_SD_read;
//reg [63:0] data_fromSD;
//reg [6:0] cnt_SD_read ;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) flag_SD_read <= 0;
    else if(n_state == SD_read_out && !MISO  && !flag_SD_read) flag_SD_read <= 1;
    else if(n_state == SD_read_out) flag_SD_read <= flag_SD_read;
    else flag_SD_read <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_SD_read <= 0;
    else if(flag_SD_read && n_state== SD_read_out) cnt_SD_read <= cnt_SD_read + 1;
    else cnt_SD_read <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) data_fromSD <= 0;
    else if(flag_SD_read && n_state== SD_read_out)  data_fromSD[63-cnt_SD_read] <= MISO;
    else data_fromSD <= data_fromSD;
end

//==============================================//
//     direction=0:DRAM read to SD write        //
//==============================================//
//SD_response_reg
always@(posedge clk or  negedge rst_n)begin
    if(!rst_n) SD_response_reg <= 0;
    else if(n_state == SD_response)begin
        SD_response_reg[0] <= MISO;
        for(i=1;i<8;i=i+1)   SD_response_reg[i] <= SD_response_reg[i-1];
    end
    else SD_response_reg <= 0;
end

///////////////////////////cnt for SD  
//reg [5:0] cnt_SD_command;
//reg [3:0] cnt_response;
//reg [3:0] cnt_wait;
//reg [6:0] cnt_SD_block;  // 0~88
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_SD_command <= 0;
    else if(n_state == SD_command) cnt_SD_command <= cnt_SD_command + 1;
    else cnt_SD_command <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_response <= 0;
    else if(n_state == wait_response && MISO == 0) cnt_response <= cnt_response + 1;
    else cnt_response <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_wait <= 0;
    else if(n_state == wait_8_cycle) cnt_wait <= cnt_wait + 1;
    else cnt_wait <= 0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_SD_block <= 0;
    else if(n_state == SD_data_in  ) cnt_SD_block <= cnt_SD_block + 1;
    else cnt_SD_block <= 0;
end

//send command to SD
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) MOSI <= 1;
    else if(n_state == SD_command) MOSI <= SD_addr_command[47-cnt_SD_command];
    else if(n_state == SD_data_in ) MOSI <= SD_data_block[87-cnt_SD_block];
    else MOSI <= 1;
end

//SD command && Data blcok
assign SD_addr_command = (direct_stored)?{2'b01,6'd17,16'd0,addr_sd_stored,CRC_7,1'b1}:{2'b01,6'd24,16'd0,addr_sd_stored,CRC_7,1'b1};
assign SD_data_block = {8'hFE,data_fromDRAM,CRC_16};
//data_fromDRAM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  data_fromDRAM <= 0;
    else if(R_READY && R_VALID)  data_fromDRAM <= R_DATA;
    else data_fromDRAM <= data_fromDRAM;
end

//DRAM read data channel
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        R_READY <= 0;
    end
    else if(n_state == DRAM_read_data_channel)begin
        R_READY <= 1;
    end
    else begin
        R_READY <= 0;
    end
end
//DRAM read addr channel
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AR_ADDR <= 0;
        AR_VALID <= 0;
    end
    else if(n_state == DRAM_read_addr_channel)begin
        AR_ADDR <= addr_dram_stored;
        AR_VALID <= 1;
    end
    else begin
        AR_ADDR <= 0;
        AR_VALID <= 0;
    end
end

// store input

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        direct_stored <= 0;
        addr_dram_stored <= 0;
        addr_sd_stored <= 0;
    end
    else if(in_valid)begin
        direct_stored <= direction;
        addr_dram_stored <= addr_dram;
        addr_sd_stored <= addr_sd;
    end
    else begin
        direct_stored <= direct_stored;
        addr_dram_stored <= addr_dram_stored;
        addr_sd_stored <= addr_sd_stored;
    end
end

//CRC//
assign CRC_7 =(direct_stored)? CRC7({2'b01,6'd17,16'd0,addr_sd_stored}): CRC7({2'b01,6'd24,16'd0,addr_sd_stored});
assign CRC_16 = CRC16_CCITT(data_fromDRAM);
//==============================================//
//             Example for function             //
//==============================================//

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    input [63:0] data;  // 40-bit data input
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^7 + x^3 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction
endmodule

