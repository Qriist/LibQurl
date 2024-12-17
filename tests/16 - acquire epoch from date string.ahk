#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_ScriptDir "\..\bin\libcurl.dll")

dateArr := []
dateArr.push("Sun, 06 Nov 1994 08:49:37 GMT")
dateArr.push("Sunday, 06-Nov-94 08:49:37 GMT")
dateArr.push("Sun Nov 6 08:49:37 1994")
dateArr.push("06 Nov 1994 08:49:37 GMT")
dateArr.push("06-Nov-94 08:49:37 GMT")
dateArr.push("Nov  6 08:49:37 1994")
dateArr.push("06 Nov 1994 08:49:37")
dateArr.push("06-Nov-94 08:49:37")
dateArr.push("1994 Nov 6 08:49:37")
dateArr.push("GMT 08:49:37 06-Nov-94 Sunday")
dateArr.push("94 6 Nov 08:49:37")
dateArr.push("1994 Nov 6")
dateArr.push("06-Nov-94")
dateArr.push("Sun Nov 6 94")
dateArr.push("1994.Nov.6")
dateArr.push("Sun/Nov/6/94/GMT")
dateArr.push("Sun, 06 Nov 1994 08:49:37 CET")
dateArr.push("06 Nov 1994 08:49:37 EST")
dateArr.push("Sun, 12 Sep 2004 15:05:58 -0700")
dateArr.push("Sat, 11 Sep 2004 21:32:11 +0200")
dateArr.push("20040912 15:05:58 -0700")
dateArr.push("20040911 +0200")
dateArr.Push(FormatTime(A_NowUTC, "yyyyMMdd hh:mm:ss"))

out := ""
for k,v in dateArr
    out .= k ": " curl.GetDate(v) "`n"

FileOpen(A_ScriptDir "\16.results.txt","w").Write(out)