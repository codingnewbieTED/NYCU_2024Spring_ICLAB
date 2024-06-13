題目:    
分別有16個IMG(8*8,16*16,32*32 8bit)和16個KERNEL(5*5 8bit)，做CONV&MAXPOOLING 和DECONV乘加運算後，沿著舉證RASTER SCANNING從LSB輸出答案。    

思路:    
1.共用CONV和DECONV，把DECONV只是zero padding四次、KERNEL反向，即可共用兩個mode。    
2.LATENCY ISSUE，切PIPELINE雖可減少乘加硬體，但老實說這次8bit乘法、20bit加法面積不會大到哪裡，用太少的乘加可能GAIN不到好處且控制訊號更多。(MY:四個 乘*5,加*5)    
3.因為一個element要serial輸出20cycle，搶第一筆輸出LATENCY關鍵，其他可慢慢算。    
4.控制訊號處理，SRAM吐資料會慢一個CYCLE，這很重要，熟悉後再去設計。        


心得:    
我最後CONV&MP 6 cycle，DECONV 5cycle(是可以1cycle，但懶著用了XD)。我覺得這次LAB最難的是如何安排SRAM位置和同時取每個SRAM不同WORD不同位置的bit做運算(當然DECONV算法共用也是關鍵，但我上學期就知道了XD)。     

1.SRAM位置照著大到小去安排就想通了(matrix id,row,col)，我開2048word,64bit/word。 matrix id(0~15,4bit),32 row(5bit)，然後COL32/8(因為每個word包含8個element) --> 2bit。    
2.因為CONV算法是一個一個滑過去乘加，會遇到不同WORD取值的情況(即邊界問題)。我的方法是開6個[7:0]img[0:7] (64bit) 存住上WORD的值，CONV pipeline五次，每次完成就往下丟(img1-->img2)    
  然後每完成一輪CONV後，下一次CONV會把img往左SHIFT2(DEONCV SHIFT1)，若到達邊界時提前控SRAM Addr吐出下一筆的WORD存入shift img最右側(若DECONV到達邊界也可直接把0丟進來)，如此控制訊號就能隨CNT_conv簡單規律完成。    
  簡單來說就是二維矩陣垂直往下SHIFT來KEEP住之前的WORD、同時下一輪CONV水平往左shift來load新的word。      


後記:    
    認真覺得想到這個架構的人才是最屌的，這題目跟上學期一樣，因為本人上學期沒修課但有follow每一堂iclab(類旁聽)，是知道bestcode架構的。    
為了避免吃像太難看，我沒把DECONV弄到1，但大家好像都不演了XD(後來lab12我有修改，deconv 1)     
    我覺得這次的真的蠻難的，明明知道架構，自己寫起來還是花很久時間，更遑論上學期還要處理deconv、SRAM size、scheduling的那些神人。    
我卡的是取不同word的bit這一關，最後想到需要水平(load new word)垂直(keep word) shift。知道要這樣做，接下來要想的是要Load什麼值，    
什麼時候要從sram取新的word。因為conv就很規律，可用cnt_conv完成所有判斷，這需要自己拿紙筆找出來。    
    最後還是抄襲問題，考古給你的設計想法+架構，實現出來請靠自己，從這邊開始一堆被抓抄襲。     

