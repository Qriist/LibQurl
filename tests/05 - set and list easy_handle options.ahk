#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

options := "INITIAL OPTIONS:`n" curl.ListOpts() "`n`n`n"

curl.SetOpt("ACCEPT_ENCODING","br")
curl.SetOpt("FOLLOWLOCATION",0)
curl.SetOpt("MAXREDIRS",99)

options .= "MODIFIED OPTIONS:`n" curl.ListOpts() "`n`n`n"

options .= "ALL KNOWN OPTIONS:`n" curl.PrintObj(curl.OptById)
FileOpen(A_ScriptDir "\05.options.txt","w").Write(options)

