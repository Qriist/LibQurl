#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

url := "https://www.titsandasses.org"
; url := "https://www.google.com"

curl.SetOpt("URL",url)
curl.HeaderToMem()
curl.WriteToMem()
lastError := curl.Sync()
; msgbox  A_Clipboard := "[[[   PERFORM   ]]]`n"
;     .   lastError "`n`n"
;     .   "[[[   HEADERS   ]]]`n" 
;     .   curl.GetLastHeaders() "`n`n"
;     .   "[[[   BODY   ]]]`n" 
;     .   curl.GetLastBody()

FileOpen(A_ScriptDir "\03.headers.txt","w").Write(curl.GetLastHeaders())
FileOpen(A_ScriptDir "\03.body.html","w").RawWrite(curl.GetLastBody())