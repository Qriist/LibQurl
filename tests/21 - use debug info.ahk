#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll","OpenSSL")
easy_handle := curl.EasyInit()
curl.EnableDebug(easy_handle)
url := "https://collectionapi.metmuseum.org/"
; url := "https://google.com"
curl.SetOpt("URL",url,easy_handle)
try curl.Sync(easy_handle)
MsgBox A_Clipboard := curl.PrintObj(curl.easyHandleMap[easy_handle]["callbacks"]["debug"]["log"])
