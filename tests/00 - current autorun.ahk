#Requires AutoHotkey v2.0

current := "12 - send and receive raw data over easy handle"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



