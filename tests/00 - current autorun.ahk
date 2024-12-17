#Requires AutoHotkey v2.0

current := "17 - using the share interface"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



