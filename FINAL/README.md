題目: 單核CPU，支援的指令有:Rtype:+,-,*,less than. Itype: beq,store,load. Mtype: determinant. 因為PERF為(latency*cycle)^3*area_core，我M指令成法器開滿多的，結果M指令助教pattern只有26個==扣掉M指令我面積17萬，加了Mtype 44萬，然後整個pattern 指令集M指令只占26/900，超搞笑...

架構: 一開始想學計組5stage pipeline的CPU，但想到要搞一堆stall,forward,flush,hazard detect等等，就卻步了。    
乖乖一個一個instr用FSM去做就好，如此可以很簡單處理SRAM cache miss時的情況(當IF,Load時miss再去DRAM取就好)，    
這次比較難的就只有SRAM cache miss怎麼寫、Store DRAM時也要更新SRAM避免重複取同位置時取到之前的值，這兩點搞定    
後就很簡單了。
1.  想好SRAM size, 搞好DRAM寫到SRAM(跟MP差不多)
2.  確定SRAM讀出來的instr,data是正確的
3.  開始寫ALU(+-*<)，這部分比MP簡單很多，instr功能很單純(除了determinant:( )
4.  寫回DRAM,SRAM,REG


APR: 我覺得這次反而花比較多時間在驗證(pattern真的好難寫)和APR上。APR做出來，06SRAM可能還是會有timing(hold)的問題，    
因為DRAM給的值是正緣變化的，直接拿DRAM的值接進SRAM會有大問題，需要加DFF和redundant mux去解決。APR真的很難，ICLAB    
也沒有琢磨在這邊太多，大部分的人只會照講義flow一直A BUG。我聽說IC contest APR用ICLAB的script是跑不出來的、不然就是
performance會跟02差很多，APR反而是很關鍵的一步，因ICLAB主要還是在教前端設計，這部分要靠自己再進修了。    

在這邊恭喜自己FP 1DE結束整學期課程了~~~ 灑花

