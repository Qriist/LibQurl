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
curl.SetOpt("URL",Download1,easy1), curl.WriteToFile(A_ScriptDir "\easy1.pgn.zst",easy1)    ;17.8mb
curl.SetOpt("URL",Download2,easy2), curl.WriteToFile(A_ScriptDir "\easy2.pgn.zst",easy2)    ;18.2mb
curl.SetOpt("URL",DownloadA,easyA), curl.WriteToFile(A_ScriptDir "\easyA.pgn.zst",easyA)    ;23.6mb
curl.SetOpt("URL",DownloadB,easyB), curl.WriteToFile(A_ScriptDir "\easyB.pgn.zst",easyB)    ;23.3mb
curl.SetOpt("URL",Download_,easy_), curl.WriteToFile(A_ScriptDir "\easy_.pgn.zst",easy_)    ;26.5mb

;download a priority file synchronously, automatically removing it from the multipool
curl.Sync(easy_)

;transfer 2 items to a different multi pool
second_multi_handle := curl.MultiInit()
curl.SwapMultiPools([easyA,easyB],first_multi_handle,second_multi_handle)
; msgbox curl.easyHandleMap[easy1]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easy2]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easyA]["associated_multi_handle"] "`n"
;     .   curl.easyHandleMap[easyB]["associated_multi_handle"] "`n"

;Download from both pools simultaneously
loop {
    check := 0
    check += curl.Async(first_multi_handle)
    check += curl.Async(second_multi_handle)
    if check = 0
        break
    sleep(10)
}
msgbox
; msgbox curl.GetLastBody(,easy1)
; msgbox "stuff"



SHA256 := Map()
SHA256["easy1"] := "aa40b3671fa3cf1072eb182892cd90b0e1e003a4a5943492f64b77e7f3fd1635"
SHA256["easy2"] := "c136acdf343293c45252906fee91e3b561fb26a936979f52dbe04bb649a2fd86"
SHA256["easyA"] := "89da64fc3c1fe3bfd571d7f626232189f3259aa728b46ea81e5cb8f3fdb34b9e"
SHA256["easyB"] := "11c795d3c81c49fa97cd958b0984c044410c78ad90f454ed08abb57ab7d00d52"
SHA256["easy_"] := "f044607c9f565831524dbedfd474100c8604dba008600bfaf1b7a48ced74c17b"
