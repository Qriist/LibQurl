#Requires AutoHotkey v2.0

current := "05 - set and list multiple options"

clean := ["txt","html"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")