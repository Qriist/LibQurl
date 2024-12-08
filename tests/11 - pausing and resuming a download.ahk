#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_WorkingDir "\bin\libcurl-x64.dll")
NormalDownload := curl.Init()
PausedDownload := curl.Init()


;We'll download this 106mb file twice.
url := "https://database.lichess.org/standard/lichess_db_standard_rated_2014-01.pgn.zst"
hash := "aa40b3671fa3cf1072eb182892cd90b0e1e003a4a5943492f64b77e7f3fd1635"
for k,v in [NormalDownload,PausedDownload] {
    easy_handle := v
    curl.SetOpt("URL",url,easy_handle)
    
    ;set the max speed on both to 3mb/s
    ;At this speed, it should take about 35 seconds to download 106mb
    ;Reduce the speed as required by your internet connection for an accurate test.
    max_speed :=  1024 * 1204 * 3
    curl.SetOpt("MAX_RECV_SPEED_LARGE",max_speed,easy_handle)
    curl.WriteToFile(A_ScriptDir "\11.body" a_index ".pgn.zst",easy_handle)
    curl.ReadyAsync(easy_handle)
}

Start := A_NowUTC

out := "Began at: " FormatTime(Start, "hh:mm:ss") "`n"

beginCount := curl.Async()  ;beginCount=2

;let some data come through, then flush whatever's there to disk
Sleep(5000)
currentCount := curl.Async()

;pause one handle       
out .= "# of running downloads before pausing: " currentCount "`n"
out .= "Paused at: " FormatTime(A_NowUTC, "hh:mm:ss") "`n"
curl.Pause(PausedDownload)

;unpause after some time has elapsed
resumeAtTimestamp := DateAdd(A_NowUTC,60,"Seconds")
out .= "Intended resume at: " FormatTime(resumeAtTimestamp, "hh:mm:ss") "`n"

resumed := 0
firstDone := 0
loop {
    currentCount := curl.Async()
    if (firstDone = 0) && (currentCount != beginCount) {
        out .= "First download completed at: " FormatTime(A_NowUTC, "hh:mm:ss") "`n"
        firstDone := 1
    }
    if (resumed = 0) && (A_NowUTC >= resumeAtTimestamp ) {
        out .= "About to unpause at: " FormatTime(A_NowUTC, "hh:mm:ss") "`n"
        out .= "# of running downloads before unpausing: " currentCount "`n"
        curl.UnPause(PausedDownload)
        resumed := 1
    }
} until !currentCount

out .= "Finished downloading at: " FormatTime(A_NowUTC, "hh:mm:ss") "`n"
out .= "Total elapsed time: " DateDiff(A_NowUTC,start,"Seconds") " seconds."

FileOpen(A_ScriptDir "\11.results.txt","w").Write(out)