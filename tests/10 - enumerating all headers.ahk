#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")
easy_handle := curl.Init()
url := "https://www.titsandasses.org"
url := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-01.pgn.zst" 
curl.SetOpt("URL",url)
curl.WriteToMem()    ;just need a transfer
curl.Sync()

str := curl.GetInfo("EFFECTIVE_URL") ;good
long := curl.GetInfo("HEADER_SIZE")    ;good
double := curl.GetInfo("SPEED_DOWNLOAD_T")  ;good
; c["PTR"] := 0x400000    ;same as SLIST
; c["SOCKET"] := 0x500000
off_t := curl.GetInfo("CONTENT_LENGTH_DOWNLOAD_T")    ;good
; c["MASK"] := 0x0fffff
; c["TYPEMASK"] := 0xf00000

; msgbox str "`n" long "`n" double ;"`n" str "`n" str "`n" str "`n" str "`n" 
msgbox off_t
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