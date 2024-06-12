題目: APR lab05

流程:     
1. floorplan: specify floorplan, 拉macro, edit halo(避免place 或 route離macro太近造成問題)    
2. powerplan: global:VDDVCC + powerring + special route(connect power pad and ring) + strip + cell power grid, DRC,LVS     
3. placement: specify not on M2,M3 layer , placement   
4. preCTS timing, clock tree synthesis, postCTS timing, Pad filler
5. nanoroute with Antenna cell  , DRC,LVS
6. SI setting, postRoute timing , add FILLER


小技巧:   
1. 拉marco，若有兩個以上，左右對齊之後LVS比較不會有問題
2. prects timing有violation沒差，postCTS為0就好
3. nanoroute有DRC直接nanoroute重點一次
4. FINAL遇到的問題，第六步加filler後有DRC(某個cell有METAL1 short)，右邊把metal1顯示出來，其他layer隱藏，刪掉short的M1，delete filler(在add filler下面)，重繞，SI+ECO timing再加filler就沒問題 (後來發現是我自己為了提高ultilization把edit halo調成12造成的問題)

預告:   
之後的lab(12 13 final)都要一直跑這個，先熟悉有利後續使用。 這個Lab接到SRAM的data都經過reg或負緣變化的input比較沒問題，我final遇到直接把MUX的input(rvalid from pseudoDRAM)接到SRAM發生06 timing violation，最終解法是
DI(rdata),WEB全部都要經過FF避免06 timing的問題，有時候只靠redundant gate無法解決，也是一個大雷點(final 繞了七八次 06都爆炸，還是建議不要拿正緣變化Input直接進SRAM，負緣就沒差)
