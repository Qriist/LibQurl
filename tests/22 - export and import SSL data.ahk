#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

; curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")
curl := LibQurl("C:\Users\Qriist\Desktop\curl\bagder\libcurl-x64.dll")

;currently bugged in curl, no point in running


url := "https://amazon.com"
; url := "https://example.com/"
; url := "https://github.com/"
; url := "https://curl.se/"
; url := "https://www.curl.se/"
curl.SetOpt("URL",url)
curl.Sync()

msgbox curl.ExportSSLs() "`n`n"
    .   curl.PrintObj(curl.shareHandleMap) "`n`n"
    .   (curl.caughtErrors.length>0?curl.PrintObj(curl.caughtErrors):"")

; if curl.caughtErrors.length > 0
;     msgbox curl.PrintObj(curl.caughtErrors)
