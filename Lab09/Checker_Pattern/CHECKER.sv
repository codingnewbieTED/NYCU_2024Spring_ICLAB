/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

   
//--------------------------------------------------------------------
//    Coverage Part                   
//---------------------------------------------------------------------		

//signal
class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

//Error_Msg err_msg;

BEV bev_info = new();

always_ff @(posedge clk) begin
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end
end

always_comb  begin
    if (inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end
end


//1. Each case of Beverage_Type should be select at least 100 times.

covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.name = "spec1";
    option.comment = "Each case of Beverage_Type should be select at least 100 times.";
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint inf.D.d_type[0]{
        //option.at_least = 100;
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

//2.	Each case of Bererage_Size should be select at least 100 times.

covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.name = "spec2";
    option.comment = "Each case of Bererage_Size should be select at least 100 times.";
    option.per_instance = 1;
    option.at_least = 100;
    bsize:coverpoint inf.D.d_size[0]{
        bins b_bev_size [] = {[L:S]};
    }
endgroup


//3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
//(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)

covergroup Spec3 @(posedge clk iff(inf.size_valid));
    option.name = "spec3";
    option.comment = "Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times.";
    option.per_instance = 1;
    option.at_least = 100;
    //coverpoint bev_info.bev_type;
    //coverpoint bev_info.bev_size;
    cross  bev_info.bev_type, bev_info.bev_size;    
endgroup

//4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)

covergroup Spec4 @(posedge clk iff(inf.out_valid));
    option.name = "spec4";
    option.comment = "Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times.";
    option.per_instance = 1;
    option.at_least = 20;
    err_msg:coverpoint inf.err_msg{
        bins b_err_msg [] = {[No_Err:Ing_OF]};
    }
endgroup

//5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)

covergroup Spec5@(posedge clk iff(inf.sel_action_valid));
    option.name = "spec5";
    option.comment = "Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times.";
    option.per_instance = 1;
    option.at_least = 200;
    act:coverpoint inf.D.d_act[0]{
        bins b_act [] = ([Make_drink:Check_Valid_Date]=>[Make_drink:Check_Valid_Date]);
    }
endgroup

//6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.

covergroup Spec6@(posedge clk iff(inf.box_sup_valid));
    option.name = "spec6";
    option.comment = "Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.";
    option.per_instance = 1;
    option.at_least = 1;
    //option.auto_bin_max = 32;
    supply:coverpoint inf.D.d_ing[0]{
        option.auto_bin_max = 32;
    }
endgroup

// Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
// Spec1_2_3 cov_inst_1_2_3 = new();
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();
Spec6 cov_inst_6 = new();



//---------------------------------------------------------------------
//    Asseration                     
//---------------------------------------------------------------------		
//glue code
typedef enum logic  [2:0] { s_idle , s_make , s_supply	, s_check  , s_wait_output}  state ;
state c_state,n_state;
logic [1:0] cnt_supply;
//cnt
always_ff@(posedge clk or negedge inf.rst_n)begin 
    if(!inf.rst_n)begin
        cnt_supply <= 0;
    end
    else if(inf.box_sup_valid)begin
        cnt_supply <= cnt_supply + 1;
    end
end
//FSM
always_ff@(posedge clk or negedge inf.rst_n)begin 
    if(!inf.rst_n)begin
        c_state <= s_idle;
    end
    else begin
        c_state <= n_state;
    end
end

always_comb begin
    case(c_state)
        s_idle: begin
            if(inf.sel_action_valid && inf.D.d_act[0] == Make_drink) n_state = s_make;
            else if(inf.sel_action_valid  && inf.D.d_act[0] == Supply    ) n_state = s_supply;
            else if(inf.sel_action_valid)                                  n_state = s_check;
            else n_state = s_idle;
        end
        s_make: begin
            if(inf.box_no_valid) n_state = s_wait_output;
            else n_state = s_make;
        end
        s_supply: begin
            if(inf.box_sup_valid && cnt_supply == 3) n_state = s_wait_output;
            else n_state = s_supply;
        end
        s_check: begin
            if(inf.box_no_valid) n_state = s_wait_output;
            else n_state = s_check;
        end
        s_wait_output: begin
            if(inf.out_valid) n_state = s_idle;
            else n_state = s_wait_output;
        end
    endcase
end



//1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
property rst_check;
    @(posedge clk)
  (inf.out_valid !== 0 || inf.err_msg !== No_Err || inf.complete !== 0 || inf.C_addr !== 0 || inf.C_data_w !== 0 || inf.C_in_valid !== 0 || inf.C_r_wb !== 0 ||
  inf.C_out_valid !== 0 || inf.C_data_r !== 0 || inf.AR_VALID !== 0 || inf.AR_ADDR !== 0 || inf.R_READY !== 0 || inf.AW_VALID !== 0 || inf.AW_ADDR !== 0 || inf.W_VALID !== 0 || inf.W_DATA !== 0|| inf.B_READY !== 0 );
endproperty: rst_check

always @(posedge inf.rst_n) begin
    assert property(rst_check) $fatal(0,"Assertion 1 is violated");
end

//2.	Latency should be less than 1000 cycles for each operation.
assert_spec2:assert property( latency_check )
    else   $fatal(0,"Assertion 2 is violated"); 


property latency_check;
    @(posedge clk) 
    c_state == s_wait_output  |->   ##[1:1000] inf.out_valid;
endproperty


//3. If error_msg == NO_ERR, complete should be 0.
always@(posedge inf.out_valid)begin
assert_spec3: assert property( complete_check )
    else   $fatal(0,"Assertion 3 is violated"); 
end

property complete_check;
    @(negedge clk)
    ( (inf.complete && inf.err_msg ==0) || inf.complete == 0);
endproperty

//4. Next input valid will be valid 1-4 cycles after previous output valid fall.

always@(posedge inf.sel_action_valid)begin
    if (n_state == s_make)
    assert property( make_valid_check)
    else   $fatal(0,"Assertion 4 is violated");
    
    if(n_state == s_supply)
    assert property( supply_valid_check)
    else   $fatal(0,"Assertion 4 is violated");
    
    if(n_state == s_check)
    assert property( date_valid_check)
    else   $fatal(0,"Assertion 4 is violated");
end

property make_valid_check;
    @(posedge clk) 
    (inf.sel_action_valid)  ##[1:4] inf.type_valid  ##[1:4] inf.size_valid ##[1:4] inf.date_valid  ##[1:4] inf.box_no_valid;
endproperty

property supply_valid_check;
    @(posedge clk) 
    (inf.sel_action_valid)  ##[1:4] inf.date_valid  ##[1:4] inf.box_no_valid  ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid; 
endproperty

property date_valid_check;
    @(posedge clk)
    (inf.sel_action_valid)  ##[1:4] inf.date_valid  ##[1:4] inf.box_no_valid;
endproperty

// 5. All input valid signals won't overlap with each other. 

always@(posedge clk)begin
    if (n_state == s_make)
    assert property( make_inter_check)
    else   $fatal(0,"Assertion 5 is violated");
    
    if(n_state == s_supply)
    assert property( supply_inter_check)
    else $fatal(0,"Assertion 5 is violated");
    
    if(n_state == s_check)
    assert property( date_inter_check)
    else  $fatal(0,"Assertion 5 is violated");
end
//C 5 choose 2 = 10
property make_inter_check;
    @(posedge clk) 
    !((inf.sel_action_valid && inf.type_valid) || (inf.type_valid && inf.size_valid) || (inf.size_valid && inf.date_valid) || (inf.date_valid && inf.box_no_valid));
endproperty
// C 4 choose 2 = 6
property supply_inter_check;
    @(posedge clk) 
    !((inf.sel_action_valid && inf.date_valid) || (inf.date_valid && inf.box_no_valid) || (inf.box_no_valid && inf.box_sup_valid) || (inf.date_valid && inf.box_sup_valid)  || (inf.sel_action_valid && inf.box_sup_valid) );
endproperty
// C 3 choose 2 = 3
property date_inter_check;
    @(posedge clk)
    !((inf.sel_action_valid && inf.date_valid) || (inf.date_valid && inf.box_no_valid) || (inf.box_no_valid && inf.sel_action_valid));
endproperty


//6. Out_valid can only be high for exactly one cycle.

assert_spec6: assert property(@(posedge clk) inf.out_valid |=> !inf.out_valid)
    else $fatal(0,"Assertion 6 is violated");

//7. Next operation will be valid 1-4 cycles after out_valid fall.
assert_spec7:  assert property(@(posedge clk) inf.out_valid |-> ##[1:4] inf.sel_action_valid)
    else $fatal(0,"Assertion 7 is violated");

//8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
always@(posedge inf.date_valid)
assert_spec8:assert property(date_is_valid)
    else $fatal(0,"Assertion 8 is violated");

property date_is_valid;
    @(posedge clk)
    ((inf.D.d_date[0].M == 1 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32) || (inf.D.d_date[0].M == 2 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 29) ||  (inf.D.d_date[0].M == 3 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32)
    || (inf.D.d_date[0].M == 4 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31) || (inf.D.d_date[0].M == 5 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32) || (inf.D.d_date[0].M == 6 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31)
    || (inf.D.d_date[0].M == 7 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32) || (inf.D.d_date[0].M == 8 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32) || (inf.D.d_date[0].M == 9 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31)
    || (inf.D.d_date[0].M == 10 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32) || (inf.D.d_date[0].M == 11 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31) || (inf.D.d_date[0].M == 12 && inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32));
endproperty

// 9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid

assert_spec9: assert property(C_in_valid_check)
    else $fatal(0,"Assertion 9 is violated");

property C_in_valid_check;
    @(posedge clk)
    inf.C_in_valid |=> !inf.C_in_valid ## [1:$] inf.C_out_valid;
endproperty



//debug//
//use if && have many fatal , must put it in else statement,cant direct behind assert
//dont know why spec 3 need negedge clk 
// spec 9 , use ##1 wrong .... use |=> right , why????
endmodule
