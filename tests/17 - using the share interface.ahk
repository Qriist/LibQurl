#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

; msgbox curl.PrintObj(curl.sOpt)
easyA := curl.Init()
easyB := curl.Init()

cookieUrl := "https://httpbin.org/cookies"
setCookie := cookieUrl "/set?" ;append key=value


;prepare the share_handle
;must be done before getting the cookie
share_handle := curl.ShareInit()
curl.ShareSetOpt("SHARE","COOKIE")
curl.AddEasyToShare(easyA)
curl.AddEasyToShare(easyB)


;get a cookie on one handle
;COOKIEFILE must be set *after* ShareSetOpt("SHARE","COOKIE")
curl.SetOpt("COOKIEFILE","",easyA)
curl.SetOpt("URL",setCookie "tidbit=is%20a%20cookie",easyA)
curl.Sync(easyA)


;see the cookie on the other
curl.SetOpt("COOKIEFILE","",easyB)
curl.SetOpt("URL",cookieUrl,easyB)
curl.Sync(easyB)
FileOpen(A_ScriptDir "\17.results.txt","w").Write(curl.GetLastBody(,easyB))


