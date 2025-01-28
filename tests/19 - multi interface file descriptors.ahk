#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
easy_handle := curl.Init()
url := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-09.pgn.zst"
curl.SetOpt("URL",url,easy_handle)


multi_handle := curl.MultiInit()
curl.ReadyAsync(easy_handle)
curl.Async()
timeout_ms := 250
extra_fds := 1
extra_nfds := 0
numfds := 0
ret := curl._curl_multi_poll(multi_handle,extra_fds,extra_nfds,timeout_ms,&numfds)

msgbox ret "`n" numfds