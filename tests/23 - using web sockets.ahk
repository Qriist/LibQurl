#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;get data to send on the websocket
acquire_handle := curl.Init()
url := "https://www.gutenberg.org/files/84/84-0.txt"    ;full text of frankenstein
curl.SetOpt("URL",url,acquire_handle)
curl.Sync(acquire_handle)

;prepare the transfer data so it doesn't break the server
content := curl.GetLastBody(,acquire_handle)
content := SubStr(content,1,1024 * 10)

;convert the connection to a websocket
url := "wss://ws.postman-echo.com/raw"
curl.SetOpt("URL",url)
curl.WebSocketConvert()

;execute the transfer
curl.WebSocketSend(content)
curl.WebSocketReceive()
FileOpen(A_ScriptDir "\23.results.txt","w").Write(curl.GetLastBody())