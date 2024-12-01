#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")

;NOTE: .MultiInit() is automatically called during .register(), 
;but can be invoked multiple times to group downloads as desired
first_multi_handle := curl.MultiInit()

;Make a few easy_handles and put them in the multi pool
;We're creating excess to test a few features in one go.
easy1 := curl.EasyInit(first_multi_handle)   ;The parameter here is optional. Each easy_handle is normally 
easy2 := curl.EasyInit(first_multi_handle)   ;automatically added to the default multi but we're overriding 
easyA := curl.EasyInit(first_multi_handle)   ;to work with several pools.
easyB := curl.EasyInit(first_multi_handle)
easy_ := curl.EasyInit(first_multi_handle)

;all of the following test downloads are under 30mb.
Download1 := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-01.pgn.zst"
Download2 := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-02.pgn.zst"
DownloadA := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-03.pgn.zst"
DownloadB := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-04.pgn.zst"
Download_ := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-05.pgn.zst"

;prepare the downloads per each handle
curl.SetOpt("URL",Download1,easy1), curl.WriteToFile(A_ScriptDir "\easy1.pgn.zst",easy1)
curl.SetOpt("URL",Download1,easy2), curl.WriteToFile(A_ScriptDir "\easy2.pgn.zst",easy2)
curl.SetOpt("URL",Download1,easyA), curl.WriteToFile(A_ScriptDir "\easyA.pgn.zst",easyA)
curl.SetOpt("URL",Download1,easyB), curl.WriteToFile(A_ScriptDir "\easyB.pgn.zst",easyB)
curl.SetOpt("URL",Download1,easy_), curl.WriteToFile(A_ScriptDir "\easy_.pgn.zst",easy_)

;download a priority file synchronously which automatically removes it from the multipool
curl.Sync(easy_)

;transfer 2 items to a different multi pool
second_multi_handle := curl.MultiInit()
curl.SwapMultiPools([easyA,easyB],first_multi_handle,second_multi_handle)
; msgbox curl.easyHandleMap[easy1]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easy2]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easyA]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easyB]["associated_multi_handle"] "`n"

;Download from both pools simultaneously
loop 10 {
    check := curl.Async()
    if check = 0
        break
    sleep(1000)
}
; msgbox
; msgbox curl.GetLastBody(,easy1)
; msgbox "stuff"