#Requires AutoHotkey v2.1-

current := 09

if !current ;catch self-launching
    current := 01

current := Format("{:02}", current)
loop files A_ScriptDir "\*.ahk"
    if InStr(A_LoopFileName " - ", current)
        found := A_LoopFileFullPath

clean := ["txt", "html", "json", "zst", "bin"]
clean := [] ;dummy while testing.
for k, v in clean
    FileDelete(A_ScriptDir "\*." v)

Run(found)