題目: 實現APR繞線的演算法，123 propagation後 retrace回來(下上右左Piority)，將指定兩個macro中的點連起來。    
      步驟為:    1. 確定能以AXI 讀出/寫入 DRAM    (INCAR mode好帥，可以一直burst資料出來><)    
                2. DRAM讀出 寫入SRAM，順便並initial map_2233 ，並實現propagation    
                3. retrace需2 cycle，讀出SRAM對應位置的entry，寫入retrace後新的path 。weight也需要讀出，cost相加輸出。    
      Performance: 面積<250, Performance = latency*Tclk

解題: 
1. 助教有給一個演算法，不需要123擴散，1122就可以實現。    (2233可用2bit counter實現)  
2. 改成2233好處為，可把0當可走區域、1為障礙、2233為擴散後的path，可以用一個bit判定是否走完    
   初始map end 為0，當map[end y][end x][1] == 1 就代表 propagation完成!    
   retrace按piority把3322改為1。begin一開始設為3，當map[start y][start x][1] == 0 就代表 retrace完成!    
3. 努力壓CYCLE，LATENCY很高，千萬不要搶latency犧牲Tclk。

技巧:    
我壓Tclk方式為    
1. 把 retrace判定四周方向(MUX)，根據Piority選擇下一個xy 這兩個操作分散兩個stage。
2. weight讀出DFF隔開，cost相加跑到第一個stage
3. SRAM開法，多word少bit更小(256*64 vs 128*128)，weight location要分開放，因為bandwidth 128

心得:    
一開始一心想壓latency，還用n_state判斷去改變map，結果Tclk變12ns。習慣很可怕，之前都無腦搶latency，請理性分析。    

然後最大收穫就是實現algorithm的硬體寫法，很像遞迴需要把問題拆成最小可重複單元去疊代，看到助教給的軟體pseudo code別怕。    
把這些小問題弄到一個cycle執行(while迴圈中的if else...)，這樣硬體就能共用(EG這次的一堆mux和if else)，很基本但非常關鍵!    


