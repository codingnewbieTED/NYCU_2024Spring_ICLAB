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
4. FINAL遇到的問題，第六步加filler後有DRC(每個cell有METAL1 short)，右邊把metal1顯示出來，其他layer隱藏，閃掉short的M1，delete filler(在add filler下面)，重繞+ECO timing，SI後再加filler就沒問題
