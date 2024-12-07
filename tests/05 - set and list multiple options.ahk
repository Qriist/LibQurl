#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

options := "INITIAL OPTIONS:`n" curl.ListOpts() "`n`n`n"

newOpts := Map("ACCEPT_ENCODING","br"
            ,"FOLLOWLOCATION",0
            ,"MAXREDIRS",99)
curl.SetOpts(newOpts)

options .= "MODIFIED OPTIONS:`n" curl.ListOpts() "`n`n`n"


options .= "ALL KNOWN OPTIONS:`n" curl.PrintObj(curl.OptById)
FileOpen(A_ScriptDir "\05.options.txt","w").Write(options)

