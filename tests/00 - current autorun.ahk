#Requires AutoHotkey v2.0

current := 27

if !current ;catch self-launching
    current := 01

current := Format("{:02}", current)
loop files A_ScriptDir "\*.ahk"
    if InStr(A_LoopFileName " - ", current)
        found := A_LoopFileFullPath

clean := ["txt", "html", "json", "zst", "bin"]
for k, v in clean
    FileDelete(A_ScriptDir "\*." v)

Run(found)