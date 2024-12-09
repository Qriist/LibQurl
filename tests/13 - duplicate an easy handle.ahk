#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

;create a handle
original := curl.Init()

;set the original handle to write to memory
curl.WriteToMem(,original)

;create a duped handle
duped := curl.DupeInit()

;intentionally do not set write destination
;this is to make sure the write handle is decoupled
; curl.WriteToMem(,duped)

;point both handles at different urls
curl.SetOpt("URL","https://titsandasses.org/",original)
curl.SetOpt("URL","https://database.lichess.org/standard/sha256sums.txt",duped)

curl.Sync(original)
curl.Sync(duped)

out := "The following data was downloaded via the ORIGINAL curl handle:`n"
out .= curl.GetLastBody(,original) "`n`n"
out .= "***************************`n`n"
out .= "The following data was downloaded via the DUPED curl handle:`n"
out .= curl.GetLastBody(,duped)

FileOpen(A_ScriptDir "\13.results.txt","w").Write(out)