#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")
easy_handle := curl.Init()
; url := "https://www.titsandasses.org"
; url := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-01.pgn.zst" 
url := "https://www.google.com"
; url := "https://www.archive.today"
curl.SetOpt("URL",url)
curl.WriteToMem()    ;just need a transfer
; curl.HeaderToFile("test.txt")
curl.Sync()
; msgbox curl.GetLastHeaders()
; curl.GetAllHeaders()

curl.InspectHeader(1)
; msgbox curl.GetInfo("REDIRECT_COUNT")   ; 2 w/archive.today
/*
st_printArr(array, depth=5, indentLevel="")
{
	for k,v in Array
	{
        
		list.= indentLevel "[" k "]"
		if (IsObject(v) && depth>1)
			list.="`n" st_printArr(v, depth-1, indentLevel . "    ")
		Else
			list.=" => " v
        ; list.="`n"
		list:=rtrim(list, "`r`n `t") "`n"
	}
	return rtrim(list)
}
*/

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
