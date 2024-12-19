#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

; msgbox curl.PrintObj(curl.sopt)
easyA := curl.Init()
easyB := curl.Init()

cookie := "https://httpbin.org/cookies"
setCookie := cookie "/set?" ;append key=value

;control for result without cookie
curl.SetOpt("URL",cookie,easyA)
curl.Sync(easyA)


;prepare the share_handle
;must be done before getting the cookie
share_handle := curl.ShareInit()
curl.ShareSetOpt("SHARE","COOKIE")
curl.AddEasyToShare(easyA)
curl.AddEasyToShare(easyB)

;get a cookie on one handle
curl.SetOpt("COOKIEFILE","",easyA)
curl.SetOpt("URL",setCookie "tidbit=is_a_cookie",easyA)
curl.Sync(easyA)
; msgbox curl.GetLastBody(,easyA)


;see the cookie on the other
curl.SetOpt("COOKIEFILE","",easyB)
curl.SetOpt("URL",cookie,easyB)
curl.Sync(easyB)
msgbox curl.GetLastBody(,easyB)
