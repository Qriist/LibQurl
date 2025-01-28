#Requires AutoHotkey v2.0

current := "19 - multi interface file descriptors"

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
run(A_ScriptDir "\" current ".ahk")



