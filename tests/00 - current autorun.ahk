#Requires AutoHotkey v2.0

current := "07 - POST from memory"

clean := ["txt","html","json"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")