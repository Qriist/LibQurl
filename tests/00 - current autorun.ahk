#Requires AutoHotkey v2.0

current := "03 - download header and file to memory"

clean := ["txt","html"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")