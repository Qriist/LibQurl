#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

curl.WriteToMem()    ;don't care about the body content

;using httpbin to force a redirect so we have multiple header indices 
url := "https://httpbin.org/redirect-to?url=https%3A%2F%2Farchive.today"
curl.SetOpt("URL",url)
curl.Sync()

redirectCount := curl.GetInfo("REDIRECT_COUNT")

out := "The total number of redirects was:  " redirectCount "`n"
out .= "Total numer of resulting header groups: " redirectCount + 1 "`n`n"

desiredHeader := "date"
;to get the first entry, use curl.InspectHeader(desiredHeader,,,0)
out .= "The initial connection was established at:  " curl.InspectHeader(desiredHeader,,,0) "`n"

;To get the final entry, use curl.InspectHeader(desiredHeader)
;(This is usually what you want.)
out .= "The final connection was established at:    " curl.InspectHeader(desiredHeader) "`n`n"

;GetAllHeaders returns a complete array of all headers for you to iterate over
allHeaders := curl.GetAllHeaders()
out .= "The following is a complete dump of all received headers:`n" curl.PrintObj(allHeaders)

FileOpen(A_ScriptDir "\10.headers.txt","w").Write(out)