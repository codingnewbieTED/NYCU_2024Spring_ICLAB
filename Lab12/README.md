題目: APR lab05

流程:     
1. floorplan: specify floorplan, 拉macro, edit halo(避免place 或 route離macro太近造成問題)    
2. powerplan: global:VDDVCC + powerring + special route(connect power pad and ring) + strip + cell power grid+ DRC,LVS     
3. placement: specify not on M2,M3 layer . placement   
4. preCTS timing, clock tree synthesis, postCTS timing
5. nanoroute with Antenna cell  + DRC,LVS
6. 
