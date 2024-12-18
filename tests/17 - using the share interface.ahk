#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

curl.SetOpt("COOKIEFILE","")
setCookie := "https://httpbin.org/cookies/set?"  ;append key=value


curl.SetOpt("URL",setCookie "tidbit=is%20a%20cookie")
; curl.SetOpt("URL","https://google.com")

; test := Buffer(256)
; msgbox curl.PrintObj(curl.easyHandleMap)
; curl.SetOpt("ERRORBUFFER",test)
curl.Sync()
; msgbox curl.PrintObj(curl.easyHandleMap)
msgbox curl.PrintObj(curl.caughtErrors)

; StrGet(test,"utf-8")
; msgbox curl.PrintObj(curl.GetVersionInfo())
msgbox curl.GetLastBody()