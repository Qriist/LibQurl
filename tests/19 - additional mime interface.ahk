#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

curl.SetOpt("URL","https://httpbin.org/anything")

mime_to_embed := curl.MimeInit()
curl.AttachMimePart("upload abc_123",123)
curl.AttachMimePart("upload abc_456",456)

; mime_to_send := curl.MimeInit()
part := curl.AttachMimePart("upload xyz",123)

test := Map("custom: mooooo",1)
; headerPtr := curl._ArrayToSList(test)

curl.SetMimePartHeaders(part,test)
; curl._curl_mime_subparts(mime_part2,mime1)

; curl.SetHeaders(test)
; curl.AttachMimeAsPart("name goes here",mime_to_embed,mime_to_send)
; mime_part := curl.AttachMimePart("Buffer",Buffer(100,255))
; curl.MimeTreatPartAsFile(mime_part,"test.jank")
; curl.MimeTreatPartAsFile(mime_part)

curl.Sync()

FileOpen(A_ScriptDir "\19.results.txt","w").Write(curl.GetLastBody())

msgbox A_Clipboard := curl.GetLastBody()
;Only pass the mime_handle, mime_parts get culled automatically
curl.MimeCleanup()