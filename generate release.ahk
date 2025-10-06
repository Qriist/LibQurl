#Requires AutoHotkey v2.0
;a simple script to compile the raw files to a single distributable library file
SetWorkingDir(A_ScriptDir)
#Include <Aris\G33kDude\cJson>
vArr := JSON.load(FileOpen(A_ScriptDir "\releases\version.json","r").Read())
pkgArr := JSON.load(FileOpen(A_ScriptDir "\package.json","r").Read())
msg := "LibQurl's current version is: " versionString(vArr) "`n`n"
    .   "Press Enter to bump the minor version.`n"
    .   "Input m to bump the major version.`n"
    .   "Input p to bump the patch."

bumped := InputBox(msg,,,versionString(vArr,"minor"))
switch bumped.Value {
    case "m":
        bumped.Value := versionString(vArr,"major",&bumpedArr)
    case versionString(vArr,"minor"):
        versionString(vArr,"minor",&bumpedArr)
    case "p":
        bumped.Value := versionString(vArr,"patch",&bumpedArr)
    default:
        bumped.Value := versionString(vArr,"do nothing",&bumpedArr)
}
If bumped.Result = "Cancel"
    ExitApp

;the build script is simply included whole sale
;this way it can fail the release script if there's a build failure
#include %A_ScriptDir%\build.ahk

pkgArr["version"] := "v" bumped.Value
FileOpen(A_ScriptDir "\package.json","w").Write(JSON.Dump(pkgArr))

releaseName := "LibQurl v" bumped.Value
releaseDir := A_ScriptDir "\releases\LibQurl v" bumped.Value
DirCreate(releaseDir)
DirCreate(releaseDir "\lib")
DirCreate(releaseDir "\bin")

libSrc := ["helper","storage","_struct","dll","_declareConstants"]  ;corresponds to each src file
core := FileOpen(A_ScriptDir "\src\core.ahk","r").Read()
core := stripHeader(core)

for k,v in StrSplit(core,"`n","`r") {
    RegExMatch(v,'mi)^(#include "\*i (<.+>))"',&found)
    if IsSet(found) && (Type(found) = "RegExMatchInfo") {
        core := StrReplace(core,found[0],"#Include " found[2])
    }
}

for k,v in libSrc {
    sub := FileOpen(A_ScriptDir "\src\" v ".ahk","r").Read()
    core := StrReplace(core,";#compile:" v,indent(stripHeader(sub)))
}
    ;stupidfdsagfdg

;get files into place
FileOpen(releaseDir "\lib\LibQurl.ahk","w").Write(core)
DirCopy(A_ScriptDir "\bin",releaseDir "\bin",1)
FileCopy(A_ScriptDir "\package.json",releaseDir,1)

;generate the release archive

cmd := A_ScriptDir "\tools\7za.exe a -mx9 " Chr(34) "..\" releaseName ".zip" Chr(34)
RunWait(cmd,releaseDir)
DirDelete(releaseDir,1)
bumpedJson := JSON.Dump(bumpedArr)
FileOpen(A_ScriptDir "\releases\version.json","w").Write(bumpedJson)

ToolTip("Compiled LibQurl release v" bumped.Value ".")
Sleep(1000)
A_Clipboard := A_ScriptDir "\releases\" releaseName ".zip"
ToolTip("Path to zipfile has been copied to clipboard.")
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
versionString(vArr,bump := 0,&bumpedArr?){
    bumpedArr ??= Map("major",vArr["major"],"minor",vArr["minor"],"patch",vArr["patch"])
    switch bump {
        case 1,"major":
            return (vArr["major"] += 1) "." (vArr["minor"] := 0) "." (vArr["patch"] := 0)
        case 2,"minor":
            return vArr["major"] "." (bumpedArr["minor"] += 1) "." (vArr["patch"] := 0)
        case 3,"patch":
            return vArr["major"] "." vArr["minor"] "." (bumpedArr["patch"] += 1)
        default:
            return (vArr["major"] "." vArr["minor"] "." vArr["patch"])       
    }
}
