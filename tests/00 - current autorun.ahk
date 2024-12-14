#Requires AutoHotkey v2.0

current := "15 - set and list multi_handle options"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



