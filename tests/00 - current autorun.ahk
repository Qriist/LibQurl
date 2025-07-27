#Requires AutoHotkey v2.0

current := 23

current := Format("{:02}",current)
loop files A_ScriptDir "\*.ahk"
	if InStr(A_LoopFileName " - ",current)
		found := A_LoopFileFullPath

clean := ["txt","html","json","zst"]
for k,v in clean
	FileDelete(A_ScriptDir "\*." v)
	
Run(found)