`ifdef RTL
	`define CYCLE_TIME_clk1 17.1
	`define CYCLE_TIME_clk2 10.1
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
`endif

module PATTERN(
	clk1,
	clk2,
	rst_n,
	in_valid,
	in_matrix_A,
	in_matrix_B,
	out_valid,
	out_matrix
);

output reg clk1, clk2;
output reg rst_n;
output reg in_valid;
output reg [3:0] in_matrix_A;
output reg [3:0] in_matrix_B;

input out_valid;
input [7:0] out_matrix;

reg [3:0] matrix_A[0:15];
reg [3:0] matrix_B[0:15];

reg [7:0] ans[0:255];
reg [7:0] out[0:255];

parameter PAT_NUM=1000;

always #(`CYCLE_TIME_clk1/2.0) clk1 = ~clk1;
always #(`CYCLE_TIME_clk2/2.0) clk2 = ~clk2;

integer i,j,k,debug,i_pat,total_latency;

always @(posedge clk1) begin
    if(out_valid===0)begin
        if(out_matrix!==0)begin
            $display("out should be 0 when out_valid is low");
            $finish;
        end
    end
end

always @(*) begin
    if(out_valid===1&&in_valid===1)begin
        $display("in_valid out_valid overlap");
            $finish;
    end
end

initial begin
    // $finish;

    reset_signal_task;

    i_pat = 0;


	
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        // $finish;
        input_task;
        // $finish;
        // wait_out_valid_task;

        cal_task;
        // $finish;
        check_ans_task;
        
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $finish;


end


reg [10:0] cnt;

task display_data; begin
	debug = $fopen("../00_TESTBED/debug.txt", "w");
	$fwrite(debug, "[PAT NO. %4d]\n\n", i_pat);
	$fwrite(debug, "in_matrix_A: ");
	for(i=0;i<16;i=i+1)begin
		$fwrite(debug, "%d ", matrix_A[i]);
	end

	$fwrite(debug, "\nin_matrix_B: ");
	for(i=0;i<16;i=i+1)begin
		$fwrite(debug, "%d ", matrix_B[i]);
	end
	$fwrite(debug, "\n");
	$fwrite(debug, "ans\n");
	for(i=0;i<16;i=i+1)begin
		for(j=0;j<16;j=j+1)begin
			$fwrite(debug, "%d ", ans[(i*16)+j]);
		end
		$fwrite(debug, "\n");
	end
end
endtask



task check_ans_task;begin
    cnt=0;
	total_latency=0;
    while(cnt<256)begin
		while(out_valid!==1)begin
			if(out_matrix!==0)begin
				$display("out should be zero");
				$finish;
			end
			@(negedge clk1);
			if(total_latency>=3000)begin
                display_data;
                $display("cycle exceed");
                $finish;
            end
			total_latency=total_latency+1;
            // $display("%d",total_latency);
			
		end
        
        if(out_valid===1)begin
           if(out_matrix!==ans[cnt])begin
				display_data;
				$display("ans_wrong");
				$display("golden_ans:%d",ans[cnt]);
				$display("your_ans:%d",out_matrix);
          		$finish;
		   end
        end
        @(negedge clk1);
        if(total_latency>=3000)begin
          $display("cycle exceed");
          $finish;
        end
		total_latency=total_latency+1;
        // $display("%d",total_latency);
		cnt=cnt+1;
        
    end

	if(out_valid===1||out_matrix!==0)begin
      $display("out_valid exceed ");
      $finish;
    end

end
endtask

task cal_task;begin
	for(i=0;i<16;i=i+1)begin
		for(j=0;j<16;j=j+1)begin
			ans[(i*16)+j]=matrix_A[i]*matrix_B[j];
		end
	end
end
endtask

task input_task; begin
    
    in_matrix_A='dx;
    in_matrix_B = 'dx;
    in_valid=0;
    for(i=0;i<16;i=i+1)begin
        in_valid=1;
        // 檢查文件是否成功打開
        // if (image_input != 0) begin
            // 使用 $fscanf 從文件中讀取數字
		in_matrix_A=$urandom_range(0, 15);
		in_matrix_B=$urandom_range(0, 15);
		matrix_A[i]=in_matrix_A;
		matrix_B[i]=in_matrix_B;


        @(negedge clk1);


    end
    in_valid=0;

    in_matrix_A='dx;
    in_matrix_B='dx;
   

   
    

end endtask 


task reset_signal_task; begin

    force clk1 = 0;
    force clk2 = 0;
    rst_n = 1;

    in_valid = 'd0;
    in_matrix_A = 'dx;
    in_matrix_B = 'dx;

    // tot_lat = 0;

    #(`CYCLE_TIME_clk1/2.0) rst_n = 0;
    #(`CYCLE_TIME_clk1/2.0) rst_n = 1;
    if (out_valid !== 0 || out_matrix !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(`CYCLE_TIME_clk1);
        $finish;
    end
    #(`CYCLE_TIME_clk1/2.0) release clk1;
     release clk2;
     @(negedge clk1);
end endtask



endmodule
