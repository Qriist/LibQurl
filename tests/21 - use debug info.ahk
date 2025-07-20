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
curl.Sync(easy_handle)
; msgbox curl.GetLastBody(,easy_handle)
; MsgBox A_Clipboard :=  curl.VersionInfo["ssl_version"] "`n" curl.PrintObj(curl.easyHandleMap[easy_handle]["callbacks"]["debug"]["log"]) "`n" curl.PrintObj(curl.caughtErrors) "`n" b ??= ""
msgbox a_clipboard := curl.PollDebug(easy_handle)

