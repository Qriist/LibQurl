#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

alpha := curl.Init()
beta := curl.Init()

alphaUrl := "https://www.titsandasses.org"
betaUrl := "https://www.google.com"

curl.SetOpt("URL",alphaUrl,alpha)
curl.SetOpt("URL",betaUrl,beta)

curl.WriteToFile(A_ScriptDir "\04.alpha.html",alpha)
curl.WriteToFile(A_ScriptDir "\04.beta.html",beta)

curl.Sync(alpha)
curl.Sync(beta)

handles := "Currently open handles:`n" curl.ListHandles() "`n`n`n"

curl.EasyCleanup(alpha)
curl.EasyCleanup(beta)

handles .= "Handles open after cleanup:`n" curl.ListHandles() "`n`n`n"

FileOpen(A_ScriptDir "\04.handles.txt","w").Write(handles)

