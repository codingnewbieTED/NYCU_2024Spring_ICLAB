PREFIX & INFIX    
症狀:  01有過 02合不出來  
解法:  
1. 題目想久一點，我考試沒用stack硬幹，很屌。
2. 題目會騙人，SPEC的output為95bit，根本和不出來，signed 15^10 41bit就可完成

心得:   
1.
習慣很可怕，不要依賴SPEC的OUTPUT大小去無腦開REG，結果這次兩個MODE，95是MODE2需要的，    
mode1根本不需要開那麼大，開95就是一個大陷阱直接讓你不能合成    
2.    
最近OT題目都是資料結構? 說好的IP、三角形呢XD 去年是stack判斷能不能排序成功，今年是兩個mode    
一個是+-*/ 後兩位數字 共9個operator 10個operand。 mode2是根據給定的演算法，push pop stack
並重新排列19個字。

後記:    
OT當時合不出來有點崩潰，回去打掉重寫弄到兩點，3個全過100 5個過part1 70 ，20多個02合不出來的跟01都做不出來的都算50分，窺爛XD    
題目多想久一點吧，若一開始想到STACK會好寫超多，並且請預估最大測資15^10需要多少bit。 弄完隔天中午助教還寄信提醒部要開95會02 must fail==，41就夠了，感覺很搞ㄟ


![螢幕擷取畫面 2024-04-15 210308](https://github.com/codingnewbieTED/NYCU_2024Spring_ICLAB/assets/152285982/fb0e16d4-5960-4761-8e5e-620d54e7634f)