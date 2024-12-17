#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")
; curl.WriteToMem()

setCookie := "https://httpbin.org/cookies/set?"  ;append key=value


curl.SetOpt("URL",setCookie "stab=tidbit")
curl.SetOpt("URL","http://google.com")

; test := Buffer(256)

; curl.SetOpt("ERRORBUFFER",test)
curl.Sync()
; StrGet(test,"utf-8")
; msgbox curl.PrintObj(curl.GetVersionInfo())
msgbox curl.GetLastBody()