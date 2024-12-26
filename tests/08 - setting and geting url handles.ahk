#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

out := "Test URL: "
url := "https://www.google.com/"
out .= url "`n`n`n"

urlHandle := curl.UrlInit()
out .= "URL handle: " urlHandle "`n`n`n"

ret := curl.UrlSet("url",url)
out .= "Return code for setting url: " ret "`n`n`n"

ret := curl.UrlGet("url")
out .= "Returned 'get' url: " ret   "`n`n`n"

ret := curl._curl_url_strerror(0)   ;"raw" for now, will be added to error handler eventually
out .= "Error string test: " StrGet(ret,"UTF-8")

FileOpen(A_ScriptDir "\08.results.txt","w").Write(out)