#Requires AutoHotkey v2.0

current := "08 - setting and geting url handles"

clean := ["txt","html","json"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")