#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;get data to send on the websocket
acquire_handle := curl.Init()
url := "https://www.gutenberg.org/files/84/84-0.txt"    ;full text of frankenstein
curl.SetOpt("URL",url,acquire_handle)
curl.Sync(acquire_handle),content := curl.GetLastBody(,acquire_handle)

;convert the connection to a websocket
url := "wss://ws.postman-echo.com/raw"
; url := "wss://httpbin.com/anything"
curl.SetOpt("URL",url)
curl.WebSocketConvert()
; curl.Sync()

; msgbox curl.GetLastHeaders() "`n`n`n" curl.GetLastBody()
; content := "payload`npayload`npayload"
content := SubStr(content,1,1024 * 50)
curl.WebSocketSend(content)
msgbox curl.WebSocketReceive() "`n`n`n" curl.GetLastBody()

MsgBox StrLen(content) "`n" StrLen(curl.GetLastBody())