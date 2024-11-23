#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

url := "https://www.titsandasses.org"
; url := "https://www.google.com"
curl.SetOpt("URL",url)
curl.HeaderToMem()
curl.WriteToMem()
lastError := curl.Perform()
; msgbox  A_Clipboard := "[[[   PERFORM   ]]]`n"
;     .   lastError "`n`n"
;     .   "[[[   HEADERS   ]]]`n" 
;     .   curl.GetLastHeaders() "`n`n"
;     .   "[[[   BODY   ]]]`n" 
;     .   curl.GetLastBody()

FileOpen(A_ScriptDir "\03.headers.txt","w").Write(curl.GetLastHeaders())
FileOpen(A_ScriptDir "\03.body.html","w").Write(curl.GetLastBody())