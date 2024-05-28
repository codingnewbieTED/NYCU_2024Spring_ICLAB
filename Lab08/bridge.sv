module bridge(input clk, INF.bridge_inf inf);
import usertype::*;


//================================================================
// FSM
//================================================================

/*
state_bridge c_state, n_state;
always_ff@(posedge clk or negedge inf.rst_n)begin 
    if(!inf.rst_n)begin
        c_state <= IDLE_bridge;
    end
    else begin
        c_state <= n_state;
    end
end


always_comb begin
    case(c_state)
        IDLE: begin
            if(inf.C_in_valid && inf.C_r_wb) n_state = READ_ADDR_CHANNEL;
            else if(inf.C_in_valid && !inf.C_r_wb) n_state = WRITE_ADDR_CHANNEL;
            else n_state = IDLE_bridge;
        end
        READ_ADDR_CHANNEL: begin
            if(inf.AR_READY) n_state = READ_DATA_CHANNEL;
            else n_state = READ_ADDR_CHANNEL;
        end
        READ_DATA_CHANNEL: begin
            if(inf.R_VALID) n_state = OUTPUT_TO_BEV;
            else n_state = READ_DATA_CHANNEL;
        end
        WRITE_ADDR_CHANNEL:begin
            if(inf.AW_READY) n_state = WRITE_DATA_CHANNEL;
            else n_state = WRITE_ADDR_CHANNEL;
        end
        WRITE_DATA_CHANNEL:begin
            if(inf.W_READY) n_state = WRITE_RESP_CHANNEL;
            else n_state = WRITE_DATA_CHANNEL;
        end
        WRITE_RESP_CHANNEL:begin
            if(inf.B_VALID) n_state = OUTPUT_TO_BEV;
            else n_state = WRITE_RESP_CHANNEL;
        end
        OUTPUT_TO_BEV: n_state = IDLE_bridge;
        default: n_state = IDLE_bridge;
    endcase
end*/


//================================================================
// READ addr channel
//================================================================
logic [16:0] in_addr_dram;
always_comb  in_addr_dram = {1'b1,5'b0,inf.C_addr,3'b0};

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.AR_VALID <= 0;
    end
    else if(inf.C_in_valid && inf.C_r_wb) begin
        inf.AR_VALID <= 1;
    end
    else if(inf.AR_VALID) begin
        inf.AR_VALID <= 0;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.AR_ADDR <= 0;
    end
    else 
        inf.AR_ADDR <= in_addr_dram;
end


//================================================================
// write addr and data channel
//================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)  inf.AW_VALID <= 0;
    else if(inf.C_in_valid && !inf.C_r_wb ) begin
        inf.AW_VALID <= 1;
    end
    else if(inf.AW_READY) begin
        inf.AW_VALID <= 0;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)  inf.AW_ADDR <= 0;
    else 
                    inf.AW_ADDR <= in_addr_dram;
end
//write data channel
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.W_VALID <= 0;
    end
    else if(inf.AW_READY) begin
        inf.W_VALID <= 1;
    end
    else if(inf.W_READY) begin
        inf.W_VALID <= 0;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.W_DATA <= 0;
    end
    else 
        inf.W_DATA <= inf.C_data_w;

end
// read/write response
always_ff@(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n)begin
        inf.B_READY <= 0;
        inf.R_READY <= 0;
    end

    else begin
        inf.B_READY <= 1;
        inf.R_READY <= 1;
    end

end

//================================================================
// OUTPUT
//================================================================

always_ff@(posedge clk or negedge inf.rst_n) begin : output_reg
    if(!inf.rst_n)begin
        inf.C_out_valid <= 0;
    end
    else if(inf.R_VALID || inf.B_VALID) begin
        inf.C_out_valid <= 1;      
    end
    else begin
        inf.C_out_valid <= 0;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n)begin
        inf.C_data_r <= 0;
    end
    else 
        inf.C_data_r <=  inf.R_DATA;        
end
endmodule