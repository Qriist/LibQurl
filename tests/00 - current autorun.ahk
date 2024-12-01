#Requires AutoHotkey v2.0

current := "09 - using the multi interface"

clean := ["txt","html","json"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")