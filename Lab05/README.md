題目:    
分別有16個IMG(8*8,16*16,32*32 8bit)和16個KERNEL(5*5 8bit)，做CONV&MAXPOOLING 和DECONV乘加    
運算後，沿著舉證RASTER SCANNING從LSB輸出答案。    

設計技巧:    
1.共用CONV和DECONV，把DECONV只是zero padding四次、KERNEL反向，即可共用兩個mode。    
2.LATENCY ISSUE，切PIPELINE雖可減少乘加硬體，但老實說這次8bit乘法、20bit加法面積    
  不會大到哪裡，用太少的乘加可能GAIN不到好處且控制訓好難處理。(MY:四個 乘*5,加*5)    
3.因為一個element要serial輸出20cycle，搶第一筆輸出LATENCY關鍵，其他可慢慢算。    
4.控制訊號處理，SRAM吐資料會慢一個CYCLE，這很重要，熟悉後再去設計。    


心得:    
我最後CONV&MP 6 cycle，DECONV 5cycle(是可以1cycle，攬著用了XD)。我覺得這次LAB最難的是如何安排SRAM位置和同時取每個SRAM不同WORD不同位置的bit做運算(當然DECONV算法共用也是    
關鍵，但我上學期就知道了XD)。     

1.SRAM位置照著大到小去安排就想通了(matrix id,row,col)，我開2048word,64bit/word。row就8*8,16*16,32*32的row(5bit)，matrix id(0~15,4bit)，然後COL   
depend on size(8 COL=0。16 COL=0,1。16 COL=0,1,2,3 即每個COL要用幾個WORD去存)。    
2.因為CONV算法是一個一個滑過去乘加，會遇到不同WORD取值的情況(即邊界問題)，我的解法是開REG(6個 [7:0]img[0:7])存住上一筆WORD的值，CONV每次SHIFT2,DEONCV    
SHIFT1，到達邊界時提前控SRAM Addr吐出下一筆的WORD存入shift REG最右側(若DECONV到達邊界也可直接把0丟進來)，如此控制訊號就能隨CNT_conv簡單規律完成。    
