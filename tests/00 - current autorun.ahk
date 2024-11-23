#Requires AutoHotkey v2.0

current := "04 - prepare and use multiple easy handles"

clean := ["txt","html"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")