#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")


curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;sample upload data used in both
postText := "The quick brown fox jumped over the lazy dog."


;working File mode
easy_handle := curl.EasyInit()
postUrl := "https://httpbin.org/put" ;site we're uploading to
curl.SetOpt("URL", postUrl, easy_handle)
curl.SetOpt("CUSTOMREQUEST", "PUT", easy_handle)

curl.autoResetToGET := 0

; prepare FileObj source
postSource := FileOpen(A_ScriptDir "\25.file.source.txt", "w")
postSource.Write(postText)

; curl.SetUpload(postSource, 16, 3, easy_handle) ;extracting "fox" from the file
; curl.WriteToFile(A_ScriptDir "\25.file.response.json")

; curl.Sync(easy_handle)
; curl.ClearPost(easy_handle)
; msgbox curl.PrintObj(curl.caughtErrors)
; msgbox curl.GetLastBody(, easy_handle)
curl.EasyCleanup(easy_handle)


;broken Buffer mode
easy_handle := curl.EasyInit()
postUrl := "https://httpbin.org/put" ;site we're uploading to
curl.SetOpt("URL", postUrl, easy_handle)
curl.SetOpt("CUSTOMREQUEST", "PUT", easy_handle)

curl.autoResetToGET := 0

;prepare Buffer source
postSource := curl._StrBuf(postText)


curl.SetUpload(postSource, 41, 3, easy_handle) ;extracting "dog" from the buffer    ;broken
curl.WriteToFile(A_ScriptDir "\25.buffer.response.json")

curl.Sync(easy_handle)
MsgBox curl.PrintObj(curl.caughtErrors)
curl.EasyCleanup(easy_handle)