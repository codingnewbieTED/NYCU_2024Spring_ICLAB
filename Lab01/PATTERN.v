//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab01 Exercise		: Supper MOSFET Calculator
//   Author     		: Lin-Hung Lai (lhlai@ieee.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME 20.0

`ifdef RTL
`define PATTERN_NUM 40
`endif
`ifdef GATE
`define PATTERN_NUM 40
`endif

module PATTERN (
    // Output signals
    opt,
    in_n0,
    in_n1,
    in_n2,
    in_n3,
    in_n4,
    // Input signals
    out_n
);

    //================================================================
    //   INPUT AND OUTPUT DECLARATION                         
    //================================================================
    output reg [2:0] opt;
    output reg [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
    input signed [9:0] out_n;

    //================================================================
    // parameters & integer
    //================================================================
    integer PATNUM = 100000;
    integer patcount;
    integer input_file, output_file;
    integer k, i, j;
    integer seed = 28;

    //================================================================
    // wire & registers 
    //================================================================
    reg [3:0] input_reg[4:0];
    reg signed [9:0] golden_ans;
    reg opt0, opt1, opt2;
    reg signed [9:0] in_n[4:0], tmp, value, avg, num1, num2, num3, num4, num5, min;
    reg signed [4:0] min_n0, min_n1, min_n2, min_n3, min_n4;
    // reg signed [9:0] /out;


    //================================================================
    // clock
    //================================================================
    reg  clk;
    real CYCLE = `CYCLE_TIME;
    always #(CYCLE / 2.0) clk = ~clk;
    initial clk = 0;

    //================================================================
    // Hint
    //================================================================
    // if you want to use c++/python to generate test data, here is 
    // a sample format for you. You can change for your convinience.
    /* input.txt format
1. [PATTERN_NUM] 

repeat(PATTERN_NUM)
	1. [opt] 
	2. [in_n0 in_n1 in_n2 in_n3 in_n4 in_n5]
*/

    /* output.txt format
1. [out_n]
*/

    //================================================================
    // initial
    //================================================================
    initial begin
        // input_file=$fopen("../00_TESTBED/in1000.txt","r");
        // output_file=$fopen("../00_TESTBED/out1000.txt","r");
        opt   = 'dx;
        in_n0 = 'dx;
        in_n1 = 'dx;
        in_n2 = 'dx;
        in_n3 = 'dx;
        in_n4 = 'dx;
        repeat (5) @(negedge clk);
        // k = $fscanf(input_file,"%d",PATNUM);

        for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
            input_task;
            repeat (1) @(negedge clk);
            check_ans;
            repeat ($urandom_range(3, 5)) @(negedge clk);
        end
        display_pass;
        repeat (3) @(negedge clk);
        $finish;
    end

    //================================================================
    // task
    //================================================================

    task input_task;
        begin
            // k = $fscanf(input_file,"%d",opt);
            opt0  = $urandom_range(0, 1);
            opt1  = $urandom_range(0, 1);
            opt2  = $urandom_range(0, 1);
            opt   = {opt2, opt1, opt0};

            // for(i = 0; i < 5; i = i + 1) 
            // k = $fscanf(input_file,"%d",input_reg[i]);

            in_n0 = $urandom_range(0, 15);
            in_n1 = $urandom_range(0, 15);
            in_n2 = $urandom_range(0, 15);
            in_n3 = $urandom_range(0, 15);
            in_n4 = $urandom_range(0, 15);
            /*
            in_n0 = $random(seed) % 'd16;
            in_n1 = $random(seed) % 'd16;
            in_n2 = $random(seed) % 'd16;
            in_n3 = $random(seed) % 'd16;
            in_n4 = $random(seed) % 'd16;

            opt   = $random(seed) % 'd8;*/


        end
    endtask

    task check_ans;
        begin
            // k = $fscanf(output_file,"%d",golden_ans);  
            ans_cal;
            if (out_n !== golden_ans) begin
                display_fail;
                $display("-------------------------------------------------------------------");
                $display("*                            PATTERN NO.%4d 	                      ",
                         patcount);
                $display("             answer should be : %d , your answer is : %d           ",
                         golden_ans, out_n);
                $display("%d %d %d %d %d ", in_n0, in_n1, in_n2, in_n3, in_n4);
                $display("%d ", (num1 + num2 + num3));
                $display("-------------------------------------------------------------------");
                #(100);
                $finish;
            end else
                $display("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);
            //$display(
            //    "    answer should be : %d , your answer is : %d ", golden_ans, out_n
            //);
        end
    endtask

    task ans_cal;
        begin
            in_n[0] = in_n0;
            in_n[1] = in_n1;
            in_n[2] = in_n2;
            in_n[3] = in_n3;
            in_n[4] = in_n4;

            if (!opt[1]) begin
                for (i = 4; i > 0; i = i - 1) begin
                    for (j = 0; j <= i - 1; j = j + 1) begin
                        if (in_n[j] > in_n[j+1]) begin
                            tmp = in_n[j];
                            in_n[j] = in_n[j+1];
                            in_n[j+1] = tmp;
                        end
                    end
                end

                if (opt[0]) begin
                    value = (in_n[0] + in_n[4]) / 2;

                    for (i = 0; i < 5; i = i + 1) begin
                        in_n[i] = in_n[i] - value;
                    end
                end

                avg  = (in_n[0] + in_n[1] + in_n[2] + in_n[3] + in_n[4]) / 5;

                num1 = in_n[0];
                num2 = in_n[1] * in_n[2];
                num3 = avg * in_n[3];
                num4 = in_n[3] * 3;
                num5 = in_n[0] * in_n[4];
                // $display("num1: %d, num2: %d, num3: %d", num1, num2, num3);

                if (!opt[2]) begin
                    golden_ans = (num1 + num2 + num3) / 3;
                end else begin
                    if (num4 > num5) golden_ans = num4 - num5;
                    else golden_ans = num5 - num4;
                end
            end else begin
                for (i = 4; i > 0; i = i - 1) begin
                    for (j = 0; j <= i - 1; j = j + 1) begin
                        if (in_n[j] < in_n[j+1]) begin
                            tmp = in_n[j];
                            in_n[j] = in_n[j+1];
                            in_n[j+1] = tmp;
                        end
                    end
                end

                if (opt[0]) begin
                    value = (in_n[0] + in_n[4]) / 2;

                    for (i = 0; i < 5; i = i + 1) begin
                        in_n[i] = in_n[i] - value;
                    end
                end

                avg  = (in_n[0] + in_n[1] + in_n[2] + in_n[3] + in_n[4]) / 5;

                num1 = in_n[0];
                num2 = in_n[1] * in_n[2];
                num3 = avg * in_n[3];
                num4 = in_n[3] * 3;
                num5 = in_n[0] * in_n[4];
                // $display("num1: %d, num2: %d, num3: %d", num1, num2, num3);

                if (!opt[2]) begin
                    golden_ans = (num1 + num2 + num3) / 3;
                end else begin
                    if (num4 > num5) golden_ans = num4 - num5;
                    else golden_ans = num5 - num4;
                end


            end

            //if (!opt[2] && opt[0])
            //   if (num1 + num2 + num3 < 0) $display("%d", (num1 + num2 + num3) / 3);


            if (patcount == 0) min = golden_ans;
            if (golden_ans < min) begin
                min = golden_ans;
                min_n0 = in_n[0];
                min_n1 = in_n[1];
                min_n2 = in_n[2];
                min_n3 = in_n[3];
                min_n4 = in_n[4];
            end


        end
    endtask

    task display_fail;
        begin
            $display("\n");
            $display("\n");
            $display("        ----------------------------               ");
            $display("        --                        --       |\__||  ");
            $display("        --  OOPS!!                --      / X,X  | ");
            $display("        --                        --    /_____   | ");
            $display("        --  \033[0;31mSimulation FAIL!!\033[m   --   /^ ^ ^ \\  |");
            $display("        --                        --  |^ ^ ^ ^ |w| ");
            $display("        ----------------------------   \\m___m__|_|");
            $display("\n");
        end
    endtask

    task display_pass;
        begin
            $display("\n");
            $display("\n");
            $display("        ----------------------------               ");
            $display("        --                        --       |\__||  ");
            $display("        --  Congratulations !!    --      / O.O  | ");
            $display("        --                        --    /_____   | ");
            $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
            $display("        --                        --  |^ ^ ^ ^ |w| ");
            $display("        ----------------------------   \\m___m__|_|");
            $display("\n");
            //$display("min: %d", min);
            //$display("%d %d %d %d %d", min_n0, min_n1, min_n2, min_n3, min_n4);
        end
    endtask



    //================================================================
    // Supplement
    //================================================================
    // if you want to use verilog to impliment a test data, here is 
    // a sample code for you. Notice that use it carefully.
    //================================================================

    // task gen_data; begin
    //     in_n0=$random(seed)%'d16;
    //     in_n1=$random(seed)%'d16;
    //     in_n2=$random(seed)%'d16;
    //     in_n3=$random(seed)%'d16;
    //     in_n4=$random(seed)%'d16;
    //     in_n5=$random(seed)%'d16;
    //     opt = $random(seed)%'d8;
    //     equ = $random(seed)%'d4; 
    // end endtask

    // task gen_golden; begin
    // 	n[0]=(opt[0])? {in_n0[3],in_n0}:{1'b0,in_n0};
    //     n[1]=(opt[0])? {in_n1[3],in_n1}:{1'b0,in_n1};
    //     n[2]=(opt[0])? {in_n2[3],in_n2}:{1'b0,in_n2};
    //     n[3]=(opt[0])? {in_n3[3],in_n3}:{1'b0,in_n3};
    //     n[4]=(opt[0])? {in_n4[3],in_n4}:{1'b0,in_n4};
    //     n[5]=(opt[0])? {in_n5[3],in_n5}:{1'b0,in_n5};
    //     $display("opt: %d equ: %d in_n0[0]=%d in_n0[1]=%d in_n0[2]=%d in_n0[3]=%d in_n0[4]=%d in_n0[5]=%d",opt, equ,n[0],n[1],n[2],n[3],n[4],n[5]);

    //     for(i=0;i<5;i=i+1) begin
    //         for(j=0;j<5-i;j=j+1) begin
    //             if(n[j]>n[j+1]) begin
    //                 temp=n[j];
    //                 n[j]=n[j+1];
    //                 n[j+1]=temp;
    //             end
    //         end
    //     end
    //     if(opt[1]) begin
    //         temp = n[0];
    //         n[0] = n[5];
    //         n[5] = temp;
    //         temp = n[1];
    //         n[1] = n[4];
    //         n[4] = temp;
    //         temp = n[2];
    //         n[2] = n[3];
    //         n[3] = temp;
    //     end
    //     $display("n[0]=%d n[1]=%d n[2]=%d n[3]=%d n[4]=%d n[5]=%d",n[0],n[1],n[2],n[3],n[4],n[5]);
    //     avg = (n[0] + n[5]) / 2;
    //     $display(" avg = %d",avg);
    //     if(opt[2]) begin
    //         n[0]=n[0]-avg;
    //         n[1]=n[1]-avg;
    //         n[2]=n[2]-avg;
    //         n[3]=n[3]-avg;
    //         n[4]=n[4]-avg;
    //         n[5]=n[5]-avg;
    //     end
    //     //$display("n[0]=%d n[1]=%d n[2]=%d n[3]=%d n[4]=%d n[5]=%d",n[0],n[1],n[2],n[3],n[4],n[5]);
    //     temp_0 = (n[0] - (n[1] * n[2]) + n[5]) / 3;
    //     temp_1 = (n[3] * 3) - (n[0] * n[4]);
    //     out_n_ans=(equ==0)?temp_0:(temp_1[8])? ~temp_1+1:temp_1;
    // end endtask

endmodule
