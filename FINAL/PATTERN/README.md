大推資工大老huang的pattern,他的pattern先隨機產生data&instr,送出去前先檢查一次load,store的address有沒有超出範圍，超出範圍則重新產生對該PC位置的instr
(雖然還是沒有解決locality的問題)。寫的超級好，不用手動產生dat黨，可以直接隨機生幾百幾千個測資驗證design
