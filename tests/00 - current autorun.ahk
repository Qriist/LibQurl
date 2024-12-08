#Requires AutoHotkey v2.0

current := "11 - pausing and resuming a download"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



