#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

url := "https://httpbin.org/anything"
curl.SetOpt("URL",url)

/*
    MimeInit() creates the mime_handle. Per curl's design, all mime_handles are 
    associated with an easy_handle at creation time. 
*/
mime_handle := curl.MimeInit()

/*
    AttachMimePart() will:
    1) initialize the part
    2) give the part a name
    3) auto-determine the mime type

    While these are sufficient for most cases, the method will also
    return the mime_part in the event you need to do other operations
*/

;attach a simple form part from normal AHK entities
curl.AttachMimePart("String","abc")
curl.AttachMimePart("Integer",123)
curl.AttachMimePart("Object",{a:"b"})
curl.AttachMimePart("Map",Map("a","b"))
curl.AttachMimePart("Array",["a","b"])
curl.AttachMimePart("Buffer",Buffer(100,255))

; ;attach a regular existing file by passing a FileObject
curl.AttachMimePart("upload abc",FileOpen(A_ScriptDir "\18.binary.upload.zip","r"))

; ;attach from a write-only file that the script created
outFile := FileOpen(A_ScriptDir "\18.text.upload.txt","w")
outFile.write(JSON.Dump(Map("Hello","World")))
curl.AttachMimePart("upload 123",outFile)

curl.Sync()

FileOpen(A_ScriptDir "\18.resultsA.txt","w").Write(curl.GetLastBody())


;we can't nest mime_handles that were already used in a transfer
mime_handle_to_nest := curl.MimeInit()
curl.AttachMimePart("String","abc")
curl.AttachMimePart("Integer",123)
curl.AttachMimePart("Object",{a:"b"})

mime2 := curl.MimeInit()
curl.AttachMimeAsPart("this is a nested mime",mime_handle_to_nest,mime2)
curl.Sync()

FileOpen(A_ScriptDir "\18.resultsB.txt","w").Write(curl.GetLastBody())

;Only pass the mime_handle, mime_parts get culled automatically
curl.MimeCleanup(mime_handle)
curl.MimeCleanup(mime2)

;do not pass mime_handles that were attached as parts
; curl.MimeCleanup(mime_handle_to_nest)
