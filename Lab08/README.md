這學期Lab08為System verilog的練習，題目很簡單，主要讓我們熟悉如何用OOP的方式管理資料(class,enum,union,typedef...)。

題目: 飲料機，八種飲料用四種配方去配置，共三種模式(make drink/supply/check date)去檢查飲料的量、日期等等，    
     並根據條件輸出對應的error，如原料不夠、overflow、expire等。    

優化: 
1. 寫回DRAM時，順便把outvalid拉起來並接收下一個pattern的輸入，可把一部分的寫入時間隱藏掉。    
2. 加減法共用，然後我好像太追latency而使用四個+法，面積有點大，或許用一個可以更好。

心得: 感覺latency的優化會被DRAM的讀取時間吃掉，所以我的方向感覺得不到什麼好處，反而是照去年的bestcode把所有運算    
      丟到bridge，減少面積會在這次LAB得到較好的performance。OOP主要在資料的管理宣告上，並不會用到其他如多型、繼承    
      等概念，SV主要還是用在pattern上比較常用，如下:

class random_supply;          
    randc ING black_supply;          
    randc ING green_supply;          
    randc ING milk_supply;          
    randc ING pineapple_supply;          
    constraint limit1{          
        black_supply inside{[0:4095]};          
        green_supply inside{[0:4095]};          
        milk_supply  inside{[0:4095]};          
        pineapple_supply inside{[0:4095]};          
    }          
endclass
random_supply IND_supply = new();          
IND_supply.randomize();          



PERF:
cycle: 1.8
area : 42550
rank:  16/93
