#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

easy_handle := curl.EasyInit()
curl.EnableDebug(easy_handle)
url := "https://collectionapi.metmuseum.org/"
url := "https://google.com"
curl.SetOpt("URL",url,easy_handle)
try curl.Sync(easy_handle)
out := curl.PollDebug(easy_handle)

FileOpen(A_ScriptDir "\21 - use debug info.txt","w").write(out)