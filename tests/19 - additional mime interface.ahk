#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

curl.SetOpt("URL","https://httpbin.org/anything")

curl.MimeInit()


;attach a regular existing file by passing a FileObject
; mime_part := curl.AttachMimePart("upload abc",FileOpen(A_ScriptDir "\18.binary.upload.zip","r"))
mime_part := curl.AttachMimePart("Buffer",Buffer(100,255))
curl.MimeTreatPartAsFile(mime_part,"test.jank")
; curl.MimeTreatPartAsFile(mime_part)

curl.Sync()

FileOpen(A_ScriptDir "\19.results.txt","w").Write(curl.GetLastBody())

msgbox curl.GetLastHeaders() "`n" curl.GetLastBody()
;Only pass the mime_handle, mime_parts get culled automatically
curl.MimeCleanup()