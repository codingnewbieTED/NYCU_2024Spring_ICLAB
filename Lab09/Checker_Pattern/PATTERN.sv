/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab08: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
/*
`ifdef RTL

  `define CYCLE_TIME 15.0
`endif

`ifdef GATE
  `define CYCLE_TIME 1.8
`endif*/
`ifndef CYCLE_TIME
`define CYCLE_TIME 15.0
`endif

`define PATNUM 3600
`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
integer i,latency,total_latency,i_pat;
real CYCLE = `CYCLE_TIME;

//================================================================
// class random
//================================================================
/*
class random_act;
    rand Action act_id;
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass



class random_bev;
    randc Bev_Type bev_id;
    constraint range{
        bev_id inside{Black_Tea,
                        Milk_Tea,
                        Extra_Milk_Tea,
                        Green_Tea,
                        Green_Milk_Tea,
                        Pineapple_Juice,
                        Super_Pineapple_Tea,
                        Super_Pineapple_Milk_Tea};
    }
endclass

class random_size;
    randc Bev_Size size_id;
    constraint range{
        size_id inside{L, M, S};
    }
endclass*/

class random_date;
    randc Month month_id;
    randc Day day_id;
    constraint range1{
        month_id inside {[1:12]};
    }
    constraint range2{
        (month_id==2) -> day_id inside {[1:28]};
        (month_id == 4 || month_id == 6 || month_id == 9 || month_id == 11) -> day_id inside {[1:30]};
        (month_id == 1 || month_id == 3 || month_id == 5 || month_id == 7 || month_id == 8 || month_id == 10 || month_id == 12 ) -> day_id inside{[1:31]};
    }
endclass

class random_box;
    randc Barrel_No box_id;
    constraint range{
        box_id inside{[0:255]};
    }
endclass

class random_supply;
    randc ING black_supply;
    randc ING green_supply;
    randc ING milk_supply;
    randc ING pineapple_supply;
    constraint limit1{
        black_supply inside{[3072:4095]};
        green_supply inside{[2048:3071]};
        milk_supply  inside{[1024:2047]};
        pineapple_supply inside{[0:1023]};
    }
endclass

//================================================================
// wire & registers 
//================================================================
//for coverage optimize
logic [1:0] mode;
logic [1:0] size_optimize;
logic [7:0] bev_optimize;
//
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];
//data from golden DRAM
ING dram_black_tea,dram_green_tea,dram_milk,dram_pineapple;
Month dram_month;
Day dram_day;
// make drink minus ING
ING make_drink_black,make_drink_green,make_drink_milk,make_drink_pineapple;
logic [63:0] dram_data;
logic [63:0] new_dram_data;
//golden
logic golden_complete;
logic [1:0] golden_err_msg;
//random object
//random_act act = new();            //instance object
//random_bev bev_type = new();
//random_size size = new();
random_date date_today = new();
random_box addr_DRAM = new();
random_supply IND_supply = new();
//================================================================
// initial
//================================================================
//initial block
initial $readmemh(DRAM_p_r, golden_DRAM);

initial begin
    total_latency = 0;
    reset_task;
    for(i_pat=0 ; i_pat < `PATNUM ; i_pat=i_pat+1) begin
        input_task;
        cal_ans;
        wait_valid;
        check_ans;
        //check_dram;
        total_latency = total_latency + latency;
        //$display("PASS    PATTERN NO.%4d  | Latency:%4d |address :%4d", i_pat,latency,addr_DRAM.box_id);
    end
    //$display("Congratulations! Cycle Time:%0.1f ns , Execution cycles: %d" , CYCLE, total_latency);
    $display("Congratulations"); //Congratulations
    $finish;
end

//task//
task reset_task; begin
    inf.rst_n = 1;
    inf.sel_action_valid = 0;
    inf.type_valid = 0;
    inf.size_valid = 0;
    inf.date_valid = 0;
    inf.box_no_valid = 0;
    inf.box_sup_valid = 0;
    inf.D = 'bx;
    force clk = 0;
    inf.rst_n = 0;
    //#(CYCLE *100);
    #(CYCLE *5);

    if(inf.out_valid !== 0 || inf.err_msg !== 2'b00 || inf.complete !== 0) begin
        $fatal(0,"reset task");  
        //$display("reset task");
        //$finish;
    end
    #(CYCLE*1);
    inf.rst_n = 1;
    release clk;
end endtask    

task input_task;begin
    //mode optimize  , 0 0 1 1 0 0 1 1  ..... 0 0 2 2 0  0 2 2 .... 1 2 1 2 1 2 1 2 ... 000000
    if(i_pat < 1600) begin
        if(i_pat % 4 == 0 || i_pat % 4 == 1)  mode = 0;
        else if(i_pat < 800)                  mode = 1;
        else                                  mode = 2;
    end
    else if(i_pat < 2000) begin
        if(i_pat % 2 == 0)                    mode = 1;
        else                                  mode = 2;
    end
    else                                      mode = 0;


    if(i_pat < 1600)      size_optimize = S;
    else if(i_pat < 2800) size_optimize = M;
    else                  size_optimize = L;

    if(i_pat < 200)       bev_optimize = 0;
    else if(i_pat < 400)  bev_optimize = 1;
    else if(i_pat < 600)  bev_optimize = 2;
    else if(i_pat < 800)  bev_optimize = 3;
    else if(i_pat < 1000) bev_optimize = 4;
    else if(i_pat < 1200) bev_optimize = 5;
    else if(i_pat < 1400) bev_optimize = 6;
    else if(i_pat < 1600) bev_optimize = 7;
    else if(i_pat < 2100) bev_optimize = 0;
    else if(i_pat < 2200) bev_optimize = 1;
    else if(i_pat < 2300) bev_optimize = 2;
    else if(i_pat < 2400) bev_optimize = 3;
    else if(i_pat < 2500) bev_optimize = 4;
    else if(i_pat < 2600) bev_optimize = 5;
    else if(i_pat < 2700) bev_optimize = 6;
    else if(i_pat < 2800) bev_optimize = 7;
    else if(i_pat < 2900) bev_optimize = 0;
    else if(i_pat < 3000) bev_optimize = 1;
    else if(i_pat < 3100) bev_optimize = 2;
    else if(i_pat < 3200) bev_optimize = 3;
    else if(i_pat < 3300) bev_optimize = 4;
    else if(i_pat < 3400) bev_optimize = 5;
    else if(i_pat < 3500) bev_optimize = 6;
    else                  bev_optimize = 7;



    
    //repeat($random()%3+1) @(negedge clk);
        @(negedge clk);
    inf.sel_action_valid = 1;
    //act.randomize();                   //instance object , and execute its default object function
    inf.D.d_act[0] = mode;       // object's member 
    @(negedge clk);
    inf.sel_action_valid = 0;
    //inf.D = 'bx;

    if(mode == Make_drink) task_MAKE_DRINK;
    else if(mode == Supply) task_SUPPLY;
    else task_Check;
end endtask

task task_MAKE_DRINK;begin
    reg [1:0] interval;

    //type input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.type_valid = 1;
    //bev_type.randomize();
    inf.D.d_type[0] = bev_optimize;
    @(negedge clk);
    inf.type_valid = 0;
    //inf.D.d_type = bev_type;
    
    //size input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);   
    inf.size_valid = 1;
    //size.randomize();
    inf.D.d_size[0] = size_optimize;
    @(negedge clk);
    inf.size_valid = 0;

    //date input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.date_valid = 1;
    date_today.randomize();
    inf.D.d_date[0] = {date_today.month_id,date_today.day_id};
    @(negedge clk);
    inf.date_valid = 0;

    //box input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.box_no_valid = 1;
    addr_DRAM.randomize();
    inf.D.d_box_no[0] = addr_DRAM.box_id;
    @(negedge clk);
    inf.box_no_valid = 0;
    inf.D = 'bx;

end endtask

task task_SUPPLY;begin
    reg [1:0] interval;

    //date input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.date_valid = 1;
    date_today.randomize();
    inf.D.d_date[0] = {date_today.month_id,date_today.day_id};
    @(negedge clk);
    inf.date_valid = 0;
    //inf.D.d_type = bev_type;
    
    //box input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);   
    inf.box_no_valid = 1;
    addr_DRAM.randomize();
    inf.D.d_box_no[0] = addr_DRAM.box_id;
    @(negedge clk);
    inf.box_no_valid = 0;

    //supply input * 4
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.box_sup_valid = 1;
    IND_supply.randomize();
    inf.D.d_ing[0] = IND_supply.black_supply;
    @(negedge clk);
    inf.box_sup_valid = 0;

    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.box_sup_valid = 1;
    inf.D.d_ing[0] = IND_supply.green_supply;
    @(negedge clk);
    inf.box_sup_valid = 0;

    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.box_sup_valid = 1;
    inf.D.d_ing[0] = IND_supply.milk_supply;
    @(negedge clk);
    inf.box_sup_valid = 0;

    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.box_sup_valid = 1;
    inf.D.d_ing[0] = IND_supply.pineapple_supply;
    @(negedge clk);
    inf.box_sup_valid = 0;
    inf.D = 'bx;

end endtask

task task_Check;begin
    reg [1:0] interval;

    //date input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);
    inf.date_valid = 1;
    date_today.randomize();
    inf.D.d_date[0] = {date_today.month_id,date_today.day_id};
    @(negedge clk);
    inf.date_valid = 0;

    //box input
    //interval = $urandom_range(0,3);
    //repeat(interval)  @(negedge clk);   
    inf.box_no_valid = 1;
    addr_DRAM.randomize();
    inf.D.d_box_no[0] = addr_DRAM.box_id;
    @(negedge clk);
    inf.box_no_valid = 0;
    inf.D = 'bx;

end endtask

task cal_ans; begin
    //supply minus
    make_drink_black = 0;
    make_drink_green = 0;
    make_drink_milk = 0;
    make_drink_pineapple = 0;
    case( {bev_optimize, size_optimize})
    {Black_Tea,L}: begin
        make_drink_black = 960;
    end
    {Black_Tea,M}: begin
        make_drink_black = 720;
    end
    {Black_Tea,S}: begin
        make_drink_black = 480;
    end
    //black:milk = 3:1
    {Milk_Tea,L}:begin    
        make_drink_black = 720;
        make_drink_milk = 240;
    end
    {Milk_Tea,M}:begin    
        make_drink_black = 540;
        make_drink_milk = 180;
    end
    {Milk_Tea,S}:begin    
        make_drink_black = 360;
        make_drink_milk = 120;
    end
    //Extra_Milk_Tea  , black:milk = 1:1
    {Extra_Milk_Tea,L}:begin    
        make_drink_black = 480;
        make_drink_milk = 480;
    end
    {Extra_Milk_Tea,M}:begin    
        make_drink_black = 360;
        make_drink_milk = 360;
    end
    {Extra_Milk_Tea,S}:begin    
        make_drink_black = 240;
        make_drink_milk = 240;
    end
    //Green_Tea ,  green : 1
    {Green_Tea,L}:begin    
        make_drink_green = 960;
    end
    {Green_Tea,M}:begin    
        make_drink_green = 720;
    end
    {Green_Tea,S}:begin    
        make_drink_green = 480;
    end
    //Green_Milk_Tea
    {Green_Milk_Tea,L}:begin
        make_drink_green = 480;
        make_drink_milk = 480;
    end
    {Green_Milk_Tea,M}:begin
        make_drink_green = 360;
        make_drink_milk = 360;
    end
    {Green_Milk_Tea,S}:begin
        make_drink_green = 240;
        make_drink_milk = 240;
    end
    {Pineapple_Juice,L}:  make_drink_pineapple = 960;
    {Pineapple_Juice,M}:  make_drink_pineapple = 720;
    {Pineapple_Juice,S}:  make_drink_pineapple = 480;
    {Super_Pineapple_Tea,L}: begin
        make_drink_black = 480;
        make_drink_pineapple = 480;
    end
    {Super_Pineapple_Tea,M}: begin
        make_drink_black = 360;
        make_drink_pineapple = 360;
    end
    {Super_Pineapple_Tea,S}: begin
        make_drink_black = 240;
        make_drink_pineapple = 240;
    end
    {Super_Pineapple_Milk_Tea,L}:begin
        make_drink_black = 480;
        make_drink_milk = 240;
        make_drink_pineapple = 240;
    end
    {Super_Pineapple_Milk_Tea,M}:begin
        make_drink_black = 360;
        make_drink_milk = 180;
        make_drink_pineapple = 180;
    end
    {Super_Pineapple_Milk_Tea,S}:begin
        make_drink_black = 240;
        make_drink_milk = 120;
        make_drink_pineapple = 120;
    end
    default:begin
        make_drink_black = 0;
        make_drink_green = 0;
        make_drink_milk = 0;
        make_drink_pineapple = 0;
    end
    endcase

    dram_data = {golden_DRAM[65536 + addr_DRAM.box_id*8 + 7],golden_DRAM[65536 + addr_DRAM.box_id*8 + 6],golden_DRAM[65536 + addr_DRAM.box_id*8 + 5],golden_DRAM[65536 + addr_DRAM.box_id*8 + 4],golden_DRAM[65536 + addr_DRAM.box_id*8 + 3],golden_DRAM[65536 + addr_DRAM.box_id*8 + 2],golden_DRAM[65536 + addr_DRAM.box_id*8 + 1],golden_DRAM[65536 + addr_DRAM.box_id*8 ]};
    dram_black_tea = dram_data[63:52];
    dram_green_tea = dram_data[51:40];
    dram_month = dram_data[39:32];
    dram_milk = dram_data[31:20];
    dram_pineapple = dram_data[19:8];
    dram_day = dram_data[7:0];

    if(mode == Make_drink) begin
        if({date_today.month_id,date_today.day_id} > {dram_month[3:0],dram_day[4:0]}) begin
           golden_complete = 0;
            golden_err_msg = No_Exp;
        end    
        else if(dram_black_tea < make_drink_black || dram_green_tea < make_drink_green || dram_milk < make_drink_milk || dram_pineapple < make_drink_pineapple)begin
            golden_complete = 0;
            golden_err_msg = No_Ing;
        end
        else begin
            golden_complete = 1;
            golden_err_msg = No_Err;
            new_dram_data[63:52] = dram_black_tea - make_drink_black;
            new_dram_data[51:40] = dram_green_tea - make_drink_green;
            new_dram_data[39:32] = dram_data[39:32];
            new_dram_data[31:20] = dram_milk - make_drink_milk;
            new_dram_data[19:8]  = dram_pineapple - make_drink_pineapple;
            new_dram_data[7:0]   = dram_data[7:0];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 7] = new_dram_data[63:56];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 6] = new_dram_data[55:48];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 5] = new_dram_data[47:40];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 4] = new_dram_data[39:32];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 3] = new_dram_data[31:24];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 2] = new_dram_data[23:16];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 1] = new_dram_data[15:8];
            golden_DRAM[65536 + addr_DRAM.box_id*8 ]    = new_dram_data[7:0];
        end
    end
    else if(mode == Supply) begin
        if( (dram_black_tea + IND_supply.black_supply) > 4095 || (dram_green_tea + IND_supply.green_supply) > 4095 || (dram_milk + IND_supply.milk_supply) > 4095 || (dram_pineapple + IND_supply.pineapple_supply) > 4095) begin
            golden_complete = 0;
            golden_err_msg = Ing_OF;
            new_dram_data[63:52] = ((dram_black_tea + IND_supply.black_supply) > 4095)? 4095 : dram_black_tea + IND_supply.black_supply;
            new_dram_data[51:40] = ((dram_green_tea + IND_supply.green_supply) > 4095)? 4095 : dram_green_tea + IND_supply.green_supply;
            new_dram_data[39:32] = date_today.month_id;
            new_dram_data[31:20] = ((dram_milk + IND_supply.milk_supply) > 4095)? 4095 : dram_milk + IND_supply.milk_supply;
            new_dram_data[19:8]  = ((dram_pineapple + IND_supply.pineapple_supply) > 4095)? 4095 : dram_pineapple + IND_supply.pineapple_supply;
            new_dram_data[7:0]   = date_today.day_id;
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 7] = new_dram_data[63:56];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 6] = new_dram_data[55:48];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 5] = new_dram_data[47:40];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 4] = new_dram_data[39:32];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 3] = new_dram_data[31:24];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 2] = new_dram_data[23:16];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 1] = new_dram_data[15:8];
            golden_DRAM[65536 + addr_DRAM.box_id*8 ]    = new_dram_data[7:0];
        end
        else begin
            golden_complete = 1;
            golden_err_msg = No_Err;
            new_dram_data[63:52] = dram_black_tea + IND_supply.black_supply;
            new_dram_data[51:40] = dram_green_tea + IND_supply.green_supply;
            new_dram_data[39:32] = date_today.month_id;
            new_dram_data[31:20] = dram_milk + IND_supply.milk_supply;
            new_dram_data[19:8]  = dram_pineapple + IND_supply.pineapple_supply;
            new_dram_data[7:0]   =  date_today.day_id;
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 7] = new_dram_data[63:56];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 6] = new_dram_data[55:48];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 5] = new_dram_data[47:40];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 4] = new_dram_data[39:32];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 3] = new_dram_data[31:24];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 2] = new_dram_data[23:16];
            golden_DRAM[65536 + addr_DRAM.box_id*8 + 1] = new_dram_data[15:8];
            golden_DRAM[65536 + addr_DRAM.box_id*8 ]    = new_dram_data[7:0];
        end
    end

    else begin
        if( {date_today.month_id,date_today.day_id} > {dram_month[3:0],dram_day[4:0]}) begin
            golden_complete = 0;
             golden_err_msg = No_Exp;
         end    
         else begin
             golden_complete = 1;
             golden_err_msg = No_Err;
         end
    end
end endtask

task wait_valid;begin
    latency = 0;
    while(inf.out_valid !== 1)begin
        if(latency == 1000) begin
            $fatal(0,"latency over 1000 cycles");
        end
        
        latency = latency + 1;
        @(negedge clk);
    end
    
end endtask

task check_ans;begin
    if(inf.out_valid === 1) begin
            if(inf.err_msg !== golden_err_msg || inf.complete !== golden_complete) begin
                $fatal(0,"Wrong Answer");
            end
    end
    @(negedge clk);
    if(inf.out_valid !== 0)
        $fatal(0,"out_valid longer than one  cycle");
end endtask



endprogram


