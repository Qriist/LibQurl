#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

curl.MultiSetOpt("MAXCONNECTS",10)
curl.MultiSetOpt("MAX_HOST_CONNECTIONS",25)
curl.ReadyAsync()

FileOpen(A_ScriptDir "\15.results.txt", "w").write(curl.PrintObj(curl.multiHandleMap))