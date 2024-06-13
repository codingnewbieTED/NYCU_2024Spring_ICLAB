# NYCU_2024Spring_ICLAB     
112下學期 ICLAB117

|      | Lab01  | Lab02 | Lab03 | Lab04 | Lab05 | Lab06 |OT |    MIDTERM PROJECT | MID EXAM |
| ------------|:------:|:-----:|:-----:|:-----:|:-----:|:-----:|:--------------:|:-----:|:-------:|
| Difficulty  |  1/5   |  1/5  |2/5|3/5|4/5|3/5|3/5|5/5|3/5||
| Rank        |  3/114 | 5/109   ||1/95|8/73|13/99|NA|2/87|5/94||
| Score       |  99.47 |   98.9 |100|100|92.2|96.36|50|99.66|94/100||
| 備註  | ||||備[1]||:(||||
| percent(%)|5|5|5|5|5|5|5|8|8|
-------------------------
|     | Lab07  | Lab08 | Lab09 | Bonus | Lab11 | Lab12 | LAB13|   FINAL PROJECT  | FINAL EXAM |
| ------------|:------:|:-----:|:-----:|:-----:|:-----:|:-----:|:--------------:|:-----:|:-------:|
| Difficulty  |2/5|2/5|2/5|1/5|3/5|1/5|1/5|5/5||||
| Rank        |1/95|16/94|38/91|NA|2/86|2|NA|||||
| Score       |100|95.16|95.89|100|99.65|99.67|100|||||
| 備註  |備[2]|||||||||||
| percent(%)|5|5|5|3|5|5|5|8|8|

備[1]:
感謝LAB5廖助教，因為我.v和.db SRAM命名不一樣導致02合成Script吃不到db黨，無法合成差點2DE，最後算NAMING ERROR只扣5分，謝謝~
提醒:script會直接把filelist裡面.v砍掉換成_WC.db去吃db黨跑02，所以名子不一樣、或沒有_WC都會吃不到喔，後面lab12,FP都是這樣。    
備[2]: 5/8 有上台分享5分鐘, + 20 分XD。 ppt有放上來

github README寫法:https://gist.github.com/billy3321/1001749662c370887c63bb30f26c9e6e    
成績公告: https://docs.google.com/spreadsheets/d/1yCiL5xkXyYOusq58-Ti7CFu0g_mKm8TVBM2_Krw-6a4/edit#gid=1576172777    


-------------------    
今年整體偏水，很多都是上學期改的，然後我上學期有旁聽... 還是建議修上學期的課，比較有機率遇到新的題目，可以練問題架構的能力，
iclab的精隨就是思考問題+設計架構，verilog實現方法就是基本工具而已。我4,5,MP聽過之前的分享，直接拿來用了，後來覺得都學別人的
不踏實，全部自己幹了。    

1. 先修、自學    
本人固態仔，我上學期修DIC才開始接觸verilog，自學YT張老的DCS課程並徵題目作業練習，旁聽ICLAB。大概期中練完DCS後開始練2023F的ICLAB2,4,5(還自己寫pseudoSRAM)
、2021S的lab2(string match machine)、lab3(數獨，遞迴FSM)，超級感謝DIC工作站，我在上面練好多東西XD。寒假寫了一點OOP、leetcode。因為我大學只修過羅設+VLSI(國半的)、旁聽計組，其他課程只能自己亂補一補，努力一點沒基礎還是能過ICLAB的!建議先修: 邏設,DCS,CA, VLSI or DIC,其他: 資結、DSP、演算法?        
2. 組隊    
找認識的一起討論架構。架構就是要一起討論+trial and error試出來的，自己硬幹可能有很多盲點(閉門造車就是我)，然後這個東西又占performance至少
70趴吧。並且有人交換pattern驗證也是非常重要的，我自己也有找人Share pattern，雖然沒有找到夥伴討論架構有點遺憾。    
3. 設計大致流程    
題目看熟直到快背起來，寫pattern。拿紙筆寫出要做的運算(如conv,*+等等)，開始分配每CYCLE要做的事(schedule一回合要做的事)、FSM,counter控制
data流動等等架構。最後運用shift reg、MUX這兩個組合技+IP運算等把deisgn刻出來，然後瘋狂優化v1,v2,v3,v4把別人捲下去XD保持24小時都在想題目的狀態，睡夢中都要想著優化。

4.  經驗談，關於架構      
      ICLAB的performance就是一門trade-off的藝術(PPA只能選兩個)，組隊的好處就是大家可以分享area,latency,CT這三條或混和的路誰的效能最好，進而找到最好的架構方向。以下個人單幹後的經驗，如果是CT固定的lab(如lab2,lab7,lab11)，不用想直接搶latency(FSM判斷都用n_state)，做完再把運算前後調整(Input delay那半個CYCLE也要試試看)，進而讓每個cycle的loading差不多，面積有可能大幅下降。 然後三個自由度全部open的lab，先試想latency可以壓到多低，若可以弄到個位數，還是建議先搶latency(如Lab5,Lab6)，你latency能壓到1cycle，面積、CT比別人大一點完全沒差、而且latency小通常比較好scheduling，寫起來比較輕鬆。
                
     再來若是較大的latency design，尤其有把DRAM latency算進來的那種，先押CT，把運算pipeline(CT下去,area也有機會變小，如lab4共用很肥的IP)，判斷if else裡面都用REG起來的control signal，降低critical path。除非lab的運算簡單到只有少數乘加法器(lab7,lab8)或是MUX(lab2,MP)，這時可以先往Area方向去思考，如多開reg幫助判斷(這部分要trial and error)、把運算共用(基本)、訊號簡化(lab8全部丟到bridge去算等)、shiftreg(lab7)。
                
      總結，先思考題目的性質，思考哪條路優化空間最大。找到方向再來就是配合演算法、思考要開的乘法加法除法器了。想拚performance就是這樣，要試試看不同架構然後最後豁然開朗知道這題關鍵在哪，久而久之架構能力、經驗才能慢慢累積
