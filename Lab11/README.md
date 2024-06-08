題目:         
low power SNN, 兩張 6X6矩陣conv後4*4 -> quant1(/2295) -> maxpooling + FC -> quant2(/510) -> L1(兩張4X1相減絕對值相加) -> activation。    

優化:        
1. CT固定15，很大，兩個除法器需要分開各占一cycle。 Scheduling: conv (運用input半個cycle算) , quant1~max , quant2 ~ activation。
2. Low power可以用一mask罩住要運算的時間，讓DFF和data只有在mask為1時變動，這樣很好達到FF + data gating (下圖)。
3. 搶latency，因FC一次會算出兩個元素，要開兩個quant2，quant1一個就好。

power心得: 講義上課都在講clock gating，但FF能省之外，不讓data跳來跳去也是一個很重要的方向。 最簡單的例子，MUX選元素丟到*+/中做運算，    
算完後把MUX固定就可以讓所有後續datapath保持不動，這個比FFgating更重要! 然後很推薦利用gating window控制gating的時間。

JG SEC DEBUG:     
這邊偷教大家，最極致的做法可以把有gating FF裡面的if else都拔掉，因為clock gating控制已經寫過一次了。缺點就是01 sec會跑超過12小時，因為    
你有加without gating跟 with的FF條件長不一樣(其實是一樣，只是移到sleep-ctrl那裏了)，但很笨proof不出問題又無法證明就卡在那邊。

    GATED_OR GATED_CG_U04 (.CLOCK(clk), .SLEEP_CTRL((!(cnt_global == 29 )&& cg_en) ) , .RST_N(rst_n), .CLOCK_GATED(clk_g1_1));
    always@(posedge clk_g1_1)begin
    	if(cnt_global == 29 ) begin   //把gating cell的 cg_en丟掉 ，就可以拔掉這個if else
    		encode_reg[0] <= encode_comb[0];
    		encode_reg[1] <= encode_comb[1];
    	end
    end

我自己個性還是求穩一點，一定要看到勾勾才安心，雖然助教說跑12小時沒出現問題就算過。 01:wocg,withg兩者只能有clk不一樣，01SEC就會過。02SEC這邊有兩個重點:       
1. cnt要寫成invalid開始為1，cnt就一直加。因為JG給值部不是連續的，這導致條件如cnt==??要做...,因cnt沒繼續加導致要取的值跑掉了。若這個值落在沒gating的範圍不會引響，但若取到的值
   是落在gating後的區段，阿這樣SEC就會說兩個design(cgen=1,cgen=0)不一樣。這超重要! JG input 不是連續，cnt要一值加!



