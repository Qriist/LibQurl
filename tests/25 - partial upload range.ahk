#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

postUrl := "https://httpbin.org/put" ;site we're uploading to
curl.SetOpt("URL", postUrl)
curl.SetOpt("CUSTOMREQUEST", "PUT")

postText := "The quick brown fox jumped over the lazy dog."

curl.autoResetToGET := 0

; prepare FileObj source
; postSource := FileOpen(A_ScriptDir "\25.file.source.txt", "w")
; postSource.Write(postText)

; curl.SetUpload(postSource, 16, 3) ;extracting "fox" from the file
; curl.WriteToFile(A_ScriptDir "\25.file.response.json")

; curl.Sync()
; curl.ClearPost()
; curl.PrintObj(curl.caughtErrors)
; msgbox curl.GetLastBody()
; MsgBox curl.PrintObj(curl.caughtErrors)


;prepare Buffer source
postSource := curl._StrBuf(postText)

curl.SetUpload(postSource) ;extracting "dog" from the file
curl.WriteToFile(A_ScriptDir "\25.buffer.response.json")

curl.Sync()
MsgBox curl.PrintObj(curl.caughtErrors)