大局關: pattern測design正確性， assertion + cover測pattern訊號的正確性與品質(覆蓋率)            

題目: 寫checker分析pattern的coverage和訊號是否符合依寫規定(assertion)。     
      part1:寫cover測助教pattern並達到100%    
      part2:寫assertion測助教有問題的design，找他錯誤的地方(很像之前的lab03)       
      part3:自己的cover + pattern測performance    
    

優化: 以pattern達到100% coverage的時間來計算分數(10分)。我以最少的組合3600筆完成，跟bestcode依樣。這部分    
      沒什麼技巧，找出最難達成的coverbin(這次好像是size & 飲料-->size & 飲料的變化次數)，並直接手動去餵測資(有點想是在考白列組合:D)，其他的cover都蠻容易達到。     
      最終: 2400個make drink，600個supply,600個check date，分別交叉給(因為有mode-->mode的transition)，make drink的bev_type+bev_size也要交叉給，errormsg可以用rand硬A    
      
心得: covergroup蠻好寫的，用coverpoint指定要追蹤的訊號+bin紀錄觸發的條件。 但assertion我覺得有點小難，有寫看似相同的寫法可能會有不一樣的結果:    
1.      ##1 和 |=> 有些情況不會依樣。    
2.      always@(..)     assert (property...)  $fatal 沒問題。
         但是!    
        always@(..)   if(..) assert (property...)  $fatal 錯誤， 加一個else 接 fatal就沒問題，不能直接放在assert後面        

可以去看checker最下面debug那邊，有點不知道為什麼，反正有問題就換個寫法A看看，畢竟大家都是第一次寫assertion           
imc可以開啟來玩玩看，看到coverbin 都是滿的有種舒暢的感覺:D            
