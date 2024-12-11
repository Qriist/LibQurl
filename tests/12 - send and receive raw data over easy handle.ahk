#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")
Run(A_ScriptDir "\12 - send and receive raw data over easy handle.py")

;configure the CURL handle
pythonServer := "127.0.0.1:12345"
curl.SetOpt("URL", pythonServer)
curl.WriteToMem()   ;don't care about the body 

;establishes the initial connection
curl.SetOpt("CONNECT_ONLY", 1) ; REQUIRED.
curl.Sync()

;you can send:
;String, Integer, Object, Array, Map, File
curl.RawSend("fingers crossed") 

;In this mode, we have to handle transmission delays ourselves
;However, once data starts to come in, RawReceive will gather the entire message before returning.
loop 
    replyBuffer := curl.RawReceive(), timesRepeated := A_Index
until (replyBuffer.size != 0)

out := "Reply received from remote: " Chr(34) StrGet(replyBuffer,"UTF-8") Chr(34) "`n`n"
out .= "Number of times RawReceive looped until success: " timesRepeated "`n`n"

FileOpen(A_ScriptDir "\12.results.txt","w").Write(out)