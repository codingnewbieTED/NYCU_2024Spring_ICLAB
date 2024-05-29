本周主題為:切pipeline,IP的使用

題目:  給定三張4*4 Img並對其做zero/replicate padding，分別對三張3*3KERNEL做CONVOLUTION後  
相加，2*2maxpooling後再對2*2舉證做舉證相乘，再來normalization和activation function後依序  
輸出四個元素。  

解題思路:  切pipeline可以開excel模擬一下每個stage在每一cycle時要輸入什麼元素。  
|--|
1.4*4IMG，padding後再做3*3捲積，還是4*4，第一筆輸入就能丟進Pipeline開始運算    
2.開excel表schedule每一cycle CONV window的九個元素，控制訊號用一個cnt即可完成  
3.16個輸入，9級乘加，第一個output第10個cycle就跑出來，需要linebuffer keep住再丟回去加  
4.norm & activation 都需要+(-)和除法，可以共用  
5.pipeline切平均一點:  1cycle: (mux + *),(  exp  ) ,( div )   

設計技巧:    
1.pipeline切平均的話，CYCLE可以壓到蠻小的，latency進而變低提高Performance。    (MY:26ns)    
2.FP的IP面積都很肥，想盡辦法去共用，讓面積縮小。   (MY: 加減法*12,mult*10,exp*1,div*1,ln*1)

心得:    
先想好pipeline scheduling，然後順著cnt把每一cycle該做的是選好。  
這次LAB還跟隊友傻傻的刻pattern，結果群組有好心學長幫寫，周五加自己的pattern總共跑了四個pattern XD    
然後可以再把conv的兩個加法器與norm/activation共用的加法器，進一步再共用，可以用10個加法器就好，交    
出去才想到。

後記:  這個best code偏水，這次lab只跟上學期有些許不同，我上學期就用Dic的帳號練過這題，並且用兩天晚上    
把薛同學的best code 完全理解，因次這次lab的scheduling基本都跟他一樣。
