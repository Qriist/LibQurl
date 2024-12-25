#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
#Include %a_scriptdir%\..\lib\Aris\SKAN\RunCMD.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

curl.SetOpt("URL","https://httpbin.org/anything")

/*
    MimeInit() creates the mime_handle. Per curl's design, all mime_handles are 
    associated with an easy_handle at creation time. 
*/
curl.MimeInit()

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

;attach a regular existing file by passing a FileObject
curl.AttachMimePart("upload abc",FileOpen(A_ScriptDir "\18.binary.upload.zip","r"))

;attach from a write-only file that the script created
outFile := FileOpen(A_ScriptDir "\18.text.upload.txt","w")
outFile.write(JSON.Dump(Map("Hello","World")))
curl.AttachMimePart("upload 123",outFile)

curl.Sync()

FileOpen(A_ScriptDir "\18.results.txt","w").Write(curl.GetLastBody())

;Only pass the mime_handle, mime_parts get culled automatically
curl.MimeCleanup()