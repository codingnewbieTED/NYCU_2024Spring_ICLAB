module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
//================================================================
//  LOGIC
//================================================================
integer i;
//input
Action act;
Bev_Type bev_type;
Bev_Size size;
Date date;
Barrel_No addr_dram;
ING supply_tea[3:0];
reg [1:0] cnt_supply;
//usage for mode_ makedirnk
logic [12:0] usage_black,usage_green,usage_milk,usage_pineapple;
state_bev c_state, n_state;
logic flag_write;//flag_read;
Data data_read;
//alu
logic n_complete;
logic [1:0] n_error_msg;
logic flag_expire , flag_overflow , flag_not_enough;
logic [12:0] a,b,c,d;
//logic [12:0] e,f,g,h;
logic [11:0] supply_a,supply_b,supply_c,supply_d;
logic [7:0] dram_month,dram_day;
//================================================================
//  FSM             
//================================================================

// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) c_state <= IDLE;
    else c_state <= n_state;
end

always_comb begin : TOP_FSM_COMB
    case(c_state)
        IDLE: begin
            if(inf.box_no_valid)  n_state = BRIDGE_READ;
            else n_state = IDLE;
        end
        BRIDGE_READ: begin  
            if(flag_write == 0) n_state  = WAIT_READ;
            else n_state = BRIDGE_READ;
        end
        WAIT_READ: begin
            if(inf.C_out_valid) n_state = CAL1;
            else n_state = WAIT_READ;
        end
        CAL1: begin                 //new_volume (plus) calculate 
            if( cnt_supply == 0) n_state = CAL2;
            else n_state = CAL1;
        end
        CAL2: begin                 //error message calculate
            if(act == Supply || (act == Make_drink && !flag_expire  && !flag_not_enough)) n_state = BRIDGE_WRITE;
            else n_state = OUTPUT;
        end
        OUTPUT: n_state = IDLE;
        BRIDGE_WRITE: n_state = IDLE;
        default: n_state = IDLE;
    endcase
end
//================================================================
//  ALU
//================================================================

always_comb dram_month = data_read[39:32];
always_comb dram_day = data_read[7:0];
always_comb flag_expire = (date > {dram_month[3:0],dram_day[4:0]})? 1:0;
always_comb flag_overflow = (a[12] || b[12] || c[12] || d[12])? 1:0;
always_comb flag_not_enough = ( a[12] && b[12] && c[12] && d[12])? 0:1;


logic [12:0] select,select1,select2,select3;
always_ff@(posedge clk) begin
    select <= (act == Make_drink)? usage_black : supply_tea[3];
    select1 <= (act == Make_drink)? usage_green : supply_tea[2];
    select2 <= (act == Make_drink)? usage_milk : supply_tea[1];
    select3 <= (act == Make_drink)? usage_pineapple : supply_tea[0];

end
always_ff@(posedge clk) begin
    a <= data_read[63:52] + select ;//supply_tea[3];
    b <= data_read[51:40] + select1;//supply_tea[2];
    c <= data_read[31:20] + select2;//supply_tea[1];
    d <= data_read[19:8]  + select3;//supply_tea[0];
    //e = data_read[63:52] + usage_black;
    //f = data_read[51:40] - usage_green;
    //g = data_read[31:20] - usage_milk;
   // h = data_read[19:8] - usage_pineapple;
end

always_comb begin
    supply_a = (a[12])? 4095: a[11:0];
    supply_b = (b[12])? 4095: b[11:0];
    supply_c = (c[12])? 4095: c[11:0];
    supply_d = (d[12])? 4095: d[11:0];
end


always_comb n_complete = ~|n_error_msg;
always_comb begin 
    /*
    if(act == Check_Valid_Date) begin
        if(flag_expire)             n_error_msg = No_Exp;
        else                        n_error_msg = No_Err;
    end*/
    if(act == Supply) begin
        if(flag_overflow)           n_error_msg =Ing_OF;
        else                        n_error_msg = No_Err;
    end
    else begin
        if(flag_expire)             n_error_msg = No_Exp;
        else if(act == Make_drink && flag_not_enough)    n_error_msg = No_Ing;
        else                        n_error_msg = No_Err;
    end
end


//================================================================
//  DATA_read&&write
//================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.C_addr <= 0;
    end
    else  begin
        inf.C_addr <= addr_dram;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.C_r_wb <= 0;
    end
    else if( c_state == BRIDGE_WRITE) begin
        inf.C_r_wb <= 0;
    end
    else begin
        inf.C_r_wb <= 1;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.C_in_valid <= 0;
    end
    else if( (c_state == BRIDGE_READ && flag_write== 0) || c_state == BRIDGE_WRITE) begin
        inf.C_in_valid <= 1;
    end
    else begin
        inf.C_in_valid <= 0;
    end
end

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.C_data_w <= 0;
    end
    else if( c_state == BRIDGE_WRITE) begin
        inf.C_data_w <= (act ==Make_drink)? {a[11:0],b[11:0],dram_month,c[11:0],d[11:0],dram_day}: {supply_a,supply_b,4'b0,date[8:5],supply_c,supply_d,3'b0,date[4:0]};
    end
    else begin
        inf.C_data_w <= inf.C_data_w;
    end
end

always_ff@(posedge clk) begin
    if(inf.C_out_valid) data_read <= inf.C_data_r;
end

//================================================================
//  FLag_control           
//================================================================
always_ff@(posedge clk or negedge inf.rst_n)begin: cnt_for_supply
    if(!inf.rst_n) cnt_supply <= 0;
    else if(inf.box_sup_valid) cnt_supply <= cnt_supply + 1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin : busy
    if(!inf.rst_n) flag_write <= 0;
    else if(c_state == BRIDGE_WRITE) flag_write <= 1;
    else if(inf.C_out_valid) flag_write <= 0;
end
//================================================================
//  INPUT REG                
//================================================================
always_ff@(posedge clk)begin : act_reg
    if(inf.sel_action_valid) act <= inf.D.d_act[0];
end

always_ff@(posedge clk)begin : type_reg
    if(inf.type_valid) bev_type <= inf.D.d_type[0];
end

always_ff@(posedge clk)begin : size_reg
    if(inf.size_valid) size <= inf.D.d_size[0];
end

always_ff@(posedge clk)begin : date_reg
    if(inf.date_valid) date <= inf.D.d_date[0];
end

always_ff@(posedge clk)begin : addr_dram_reg
    if(inf.box_no_valid) addr_dram <= inf.D.d_box_no[0];
end

always_ff@(posedge clk)begin : supply_tea_reg
    if(inf.box_sup_valid) begin 
        supply_tea[0] <= inf.D.d_ing[0];
        for(i=1;i<4;i=i+1) supply_tea[i] <= supply_tea[i-1];
    end
end
//================================================================
//  Ingrediant usage for BEV                
//================================================================
always_comb begin : ingrediant_usage
    usage_black = 4096;
    usage_green = 4096;
    usage_milk = 4096;
    usage_pineapple = 4096;

    case(bev_type)
        Black_Tea: begin
            case(size)
                L: usage_black = 3136;
                M: usage_black = 3376;
                default: usage_black = 3616;
            endcase
        end
        Milk_Tea: begin  //black : milk = 3:1
            case(size)
                L: begin
                    usage_black = 3376;
                    usage_milk = 3856;
                end
                M: begin
                    usage_black = 3556;
                    usage_milk = 3916;
                end
                default: begin
                    usage_black = 3736;
                    usage_milk = 3976;
                end
            endcase
        end
        Extra_Milk_Tea: begin  //black:milk = 1:1
            case(size)
                L: begin
                    usage_black = 3616;
                    usage_milk = 3616;
                end
                M: begin
                    usage_black = 3736;
                    usage_milk = 3736;
                end
                default: begin
                    usage_black = 3856;
                    usage_milk = 3856;
                end
            endcase
        end
        Green_Tea: begin  //green 1
            case(size)
                L: usage_green = 3136;
                M: usage_green = 3376;
                default: usage_green = 3616;
            endcase
        end
        Green_Milk_Tea: begin  //green 1 : milk 1
            case(size)
                L: begin
                    usage_green = 3616;
                    usage_milk = 3616;
                end
                M: begin
                    usage_green = 3736;
                    usage_milk = 3736;
                end
                default: begin
                    usage_green = 3856;
                    usage_milk = 3856;
                end
            endcase
        end
        Pineapple_Juice: begin
            case(size)
                L: usage_pineapple = 3136;
                M: usage_pineapple = 3376;
                default: usage_pineapple = 3616;
            endcase
        end
        Super_Pineapple_Tea: begin  //green 1 : pineapple 1
            case(size)
                L: begin
                    usage_black = 3616;
                    usage_pineapple = 3616;
                end
                M: begin
                    usage_black = 3736;
                    usage_pineapple = 3736;
                end
                default: begin
                    usage_black = 3856;
                    usage_pineapple = 3856;
                end
            endcase
        end
        default: begin
            case(size)   // black:milk:pineapple = 2:1:1
                L: begin
                    usage_black = 3616;
                    usage_milk = 3856;
                    usage_pineapple = 3856;
                end
                M: begin
                    usage_black = 3736;
                    usage_milk = 3916;
                    usage_pineapple = 3916;
                end
                default: begin
                    usage_black = 3856;
                    usage_milk = 3976;
                    usage_pineapple = 3976;
                end
            endcase
        end
    endcase
end

//================================================================
//  Output Reg              
//================================================================
//to pattern
always_ff @(posedge clk or negedge inf.rst_n) begin : output_to_pattern
    if(!inf.rst_n) begin
        inf.out_valid <= 0;
    end
    else if(c_state == BRIDGE_WRITE || c_state == OUTPUT)begin
        inf.out_valid <= 1;
    end
    else begin
        inf.out_valid <= 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : output_to_pattern1
    if(!inf.rst_n) begin
        inf.err_msg <= 0;
        inf.complete <= 0;
    end
    else begin
        inf.err_msg <=  n_error_msg;
        inf.complete <= n_complete;

    end
end
//to bridge


endmodule