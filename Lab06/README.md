題目: 資料結構?TREE類型題目，排序後將最小兩者建構一顆subtree，weight想同則照原本的順序，左右方向1/0編碼構成huffman code。    
      共七個元素要排，需要排序七次，merge tree七次。    

解題:    
1.使用stable sort ，若B<A再交換(等於就維持)。    
2.適當的使用insertion sort，IP是重頭排到尾(merge sort 或 bubble sort)。實際上形成subtree只要經過一個insertion sort(三級比較器)就好了。    
3.encode一開始沒啥概念，左右形成子樹後，必須保留原本的訊息(這顆子樹包含哪一些字母)，這應該是這次題目唯一要想一下的地方。(方式如下)    

    encoder_table[0] = 8'b00000001;    
    encoder_table[1] = 8'b00000010;    
    encoder_table[2] = 8'b00000100;    
    encoder_table[3] = 8'b00001000;    
    encoder_table[4] = 8'b00010000;    
    encoder_table[5] = 8'b00100000;    
    encoder_table[6] = 8'b01000000;    
    encoder_table[7] = 8'b10000000;    
    assign encoder_exist_list_1 = encoder_table[out_addr_sort_1[7:4]] | encoder_table[out_addr_sort_1[3:0]] ;    //sort完後最後兩者去or    
    assign encoder_exist_list_2 = encoder_table[out_addr_sort_2[7:4]] | encoder_table[out_addr_sort_2[3:0]] ;    
然後for回圈去看哪個bit會是1，depth+1;    
node 也是for迴圈判斷encoder_table[out_addr_sort_1[7:4]  node就+1  ;    encoder_table[out_addr_sort_1[3:0]] 左方加0。    

performance: Area:42987.873435  Latency:4   Clk:7.5   
(高手:area:33322, Latency:7 CLK:4.5 應該也是insertion sort，只是我去槍latency一個cycle塞兩個insertion sort，他Performance比我好)    

心得:    
一開始擔心軟體的寫法 matrix[reg]到底
