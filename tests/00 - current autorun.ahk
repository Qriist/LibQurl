#Requires AutoHotkey v2.0

current := "16 - acquire epoch from date string"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



