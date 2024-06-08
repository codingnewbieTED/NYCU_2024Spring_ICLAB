題目: low power SNN, 兩張 6X6矩陣conv後4*4 -> quant(/2295) -> maxpooling + FC -> quant(/510) -> L1(兩張4X1相減絕對值相加) -> activation。    

優化:
    CT固定15，很大，兩個除法器需要分開各占一cycle。 Scheduling: conv (運用input半個cycle算) , quant1~max , quant2 ~ activation。 latency:1     
