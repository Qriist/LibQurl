#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

/*
    TraceMime creates a deterministic
*/
m1 := curl.MimeInit()
m2 := curl.MimeInit()
m3 := curl.MimeInit()

;build some mimes
loop 3 {
    curl.AttachMimePart("String", "abc", m%a_index%)
    curl.AttachMimePart("Object", { a: "b" }, m%a_index%)
    curl.AttachMimePart("Buffer", Buffer(10, 81), m%a_index%)
}

; The method returns a browsable object plus a deterministic hash
viewMime := curl.TraceMime(m1)
msgbox curl.PrintObj(viewMime) "`n`n`n.traceHash=" viewMime.traceHash
; ExitApp
;identically built mimes hash the same
msgbox curl.TraceMime(m1).traceHash "`n`n`n"
. curl.TraceMime(m2).traceHash "`n`n`n"
. curl.TraceMime(m3).traceHash "`n`n`n"

; add a single extra element to the middle mime,
; then only the first and third match
curl.AttachMimePart("Extra", "Part", m2)
msgbox curl.TraceMime(m1).traceHash "`n`n`n"
. curl.TraceMime(m2).traceHash "`n`n`n"
. curl.TraceMime(m3).traceHash "`n`n`n"