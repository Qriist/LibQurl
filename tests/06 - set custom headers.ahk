﻿#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

curl.SetOpt("URL","https://httpbin.org/headers")
curl.SetHeaders(Map("tidbit","is a header"
                    ,"Custom","header2"
                    ,"Custom-Header","3"))

curl.HeaderToFile(A_ScriptDir "\06.headers.txt")
curl.WriteToFile(A_ScriptDir "\06.body.json")

curl.Perform()