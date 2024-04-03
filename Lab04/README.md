本周主題為:切pipeline,IP的使用

題目:  給定三張4*4 Img並對其做zero/replicate padding，分別對三張3*3KERNEL做CONVOLUTION後  
相加，2*2maxpooling後再對2*2舉證做舉證相乘，再來normalization和activation function後依序  
輸出四個元素。  

解題思路:  切pipeline可以開excel模擬一下每個stage在每一cycle時要輸入什麼元素。  
|--|
1.我發現4*4IMG，padding後再做3*3捲積，還是4*4，這代表第一筆邊輸入就能開始運算    
2.開excel表，window的九個元素很好找且規律，控制訊號用一個cnt即可完成  
3.16個輸入，9級乘加，第一個output第10個cycle就跑出來，請用linebuffer keep住他再丟回去加  
4.norm & activation 都需要+(-)和除法，可以共用  
5.pipeline切平均一點:  1cycle: (mux + *),(  exp  ) ,( div )   

設計技巧:    
1.pipeline切平均的話，CYCLE可以壓到蠻小的，latency進而變低提高Performance。    (MY:26ns)    
2.FP的IP面積都很肥，想盡辦法去共用，讓面積縮小。   (MY: 加減法*9,mult*7,exp*1,div*1,ln*1)

心得:    
題目不難，先想好架構、mux元素怎麼給順著cnt做就能刻得出來，週四上午考完計組後，晚上完成。  
這次LAB還跟隊友傻傻  的刻pattern，結果群組有好心學長幫寫，周五加自己的pattern總共跑了四個pattern XD    
然後可以再把conv的兩個加法器與norm/activation共用的加法器，進一步再共用，可以用七個加法器就好，交    
出去才想到。
