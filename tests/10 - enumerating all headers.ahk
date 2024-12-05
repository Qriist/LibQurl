#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")
easy_handle := curl.Init()
url := "https://www.titsandasses.org"
curl.SetOpt("URL",url)
curl.WriteToMem()    ;just need a transfer
curl.Sync()

; c["STRING"] := 0x100000
msgbox long := curl.GetInfo("HEADER_SIZE")    ;good
; c["DOUBLE"] := 0x300000
; c["SLIST"] := 0x400000
; c["PTR"] := 0x400000    ;same as SLIST
; c["SOCKET"] := 0x500000
; c["OFF_T"] := 0x600000
; c["MASK"] := 0x0fffff
; c["TYPEMASK"] := 0xf00000



; curl._curl_easy_header(easy_handle)


; _curl_easy_getinfo(easy_handle,info,&retCode) {  ;untested   https://curl.se/libcurl/c/curl_easy_getinfo.html
;     return DllCall(this.curlDLLpath "\curl_easy_getinfo"
;         ,   "Ptr", easy_handle
;         ,   "UInt", info
;         ,   "Int", retCode)
; }
; _curl_easy_header(easy_handle,name,index,origin,request) {   ;untested https://curl.se/libcurl/c/curl_easy_header.html
;     return DllCall(this.curlDLLpath "\curl_easy_header"
;         ,   "Ptr", name
;         ,   "Int", index
;         ,   "Int", origin
;         ,   "Int", request
;         ,   "Ptr")
; }

; _curl_easy_nextheader(easy_handle,origin,request,prev) { ;untested https://curl.se/libcurl/c/curl_easy_nextheader.html
;     return DllCall(this.curlDLLpath "\curl_easy_nextheader"
;         ,   "Int", origin
;         ,   "Int", request
;         ,   "Ptr", prev
;         ,   "Ptr")
; }