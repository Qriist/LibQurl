#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
#Include %a_scriptdir%\..\lib\Aris\SKAN\RunCMD.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

easy_handle := curl.Init()

mime_handle := curl.MimeInit(easy_handle)

curl.AttachMimePart("sketch","pad",mime_handle)

curl.SetOpt("URL","https://httpbin.org/anything")
curl.sync()

msgbox curl.GetLastBody()
ExitApp
test := FileOpen(A_ScriptDir "\07.binary.upload.zip","r")
MsgBox _GetFilePathFromFileObject(test)


_GetFilePathFromFileObject(FileObject) {
    static GetFinalPathNameByHandleW := DllCall("Kernel32\GetProcAddress", "Ptr", DllCall("Kernel32\GetModuleHandle", "Str", "Kernel32", "Ptr"), "AStr", "GetFinalPathNameByHandleW", "Ptr")

    ; if !FileObject
        ; throw Error("Invalid file handle")

    ; Initialize a buffer to receive the file path
    static bufSize := 65536    ;64kb to accomodate long path names in UTF-16
    buf := Buffer(bufSize)

    ; Call GetFinalPathNameByHandleW
    len := DllCall(GetFinalPathNameByHandleW
        ,   "Ptr", FileObject.handle       ; File handle
        ,   "Ptr", buf         ; Buffer to receive the path
        ,   "UInt", bufSize    ; Size of the buffer (in wchar_t units)
        ,   "UInt", 0          ; Flags (0 for default behavior)
        ,   "UInt")            ; Return length of the file path

    if (len == 0 || len > bufSize)
        throw Error("Failed to retrieve file path or insufficient buffer size", A_LastError)

    ; Return the result as a string
    return StrGet(buf, "UTF-16")
}

;ts\LibQurl\bin\file.exe"
; magic_cmd := " -m magic.mgc -b --mime-type "

; testfile := A_ScriptDir "\..\bin\icudt74.dll"

; start := A_NowUTC
; msgbox RunCMD(magic magic_cmd Chr(34) testfile Chr(34),"C:\Projects\LibQurl\bin")
; end := A_NowUTC

; msgbox start "`n" end


