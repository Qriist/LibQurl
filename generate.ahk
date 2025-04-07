#Requires AutoHotkey v2.0
;a simple script to compile the raw files to a single distributable library file
SetWorkingDir(A_ScriptDir)


libSrc := ["helper","storage","_struct","dll","_declareConstants"]  ;corresponds to each src file
core := FileOpen(A_ScriptDir "\src\core.ahk","r").Read()
core := stripHeader(core)

; for k,v in StrSplit(core,"`n","`r") {
;     RegExMatch(v,'mi)^(#include "\*i (<.+>))"',&found)
;     if IsSet(found) && (Type(found) = "RegExMatchInfo") {
;         core := StrReplace(core,found[0],"#Include " found[2])
;     }
; }

for k,v in libSrc {
    sub := FileOpen(A_ScriptDir "\src\" v ".ahk","r").Read()
    core := StrReplace(core,";#compile:" v,indent(stripHeader(sub)))
}
    ;stupidfdsagfdg

FileOpen(A_ScriptDir "\lib\LibQurl.ahk","w").Write(core)

ToolTip("Compiled LibQurl")
Sleep(1000)
ExitApp

stripHeader(input){
    return Trim(RegExReplace(input,"ms)(^.+;\*{3})",,,1),"`r`n")
}
indent(input){
    ;RegExReplace was giving me random extra lines, using simple loop for now
    ;return RegExReplace(input,"m)(^)","    ")
    
    ret := ""
    for k,v in StrSplit(input,"`n","`r")
        ret .= "    " v "`n" 
    return ret
}

