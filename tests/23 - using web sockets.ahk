#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

; curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

; url := "wss://httpbin.org/anything"
; curl.SetOpt("URL",url)
; curl.SetOpt("CONNECT_ONLY",2)
; curl.SetPost("PAYLOAD")
; curl.Sync()

; msgbox curl.GetLastHeaders() "`n`n`n" curl.GetLastBody()
