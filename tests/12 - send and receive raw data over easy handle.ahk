#Requires AutoHotKey v2.1-
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
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

;always returns a buffer
replyBuffer := curl.RawReceive()

out := "Reply received from remote: " Chr(34) StrGet(replyBuffer, "UTF-8") Chr(34) "`n`n"
; out .= "Number of times RawReceive looped until success: " timesRepeated "`n`n"
msgbox out
; MsgBox A_Clipboard := curl.printObj(curl.caughtErrors)
FileOpen(A_ScriptDir "\12.results.txt", "w").Write(out)