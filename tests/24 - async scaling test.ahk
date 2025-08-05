#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;NOTE: .MultiInit() is automatically called during .register(), 
;but can be invoked multiple times to group downloads as desired

speed := 80	;network's connection in Mbps
handleCount := 100	;number of easy_handles to generate
m := curl.MultiInit()
;determine an evenly split speed based on bandwidth and handles
speed := speed * 1000000	;bits
speed := speed / handleCount ;split
speed := floor(speed / 8)	;bytes

url := "http://localhost:8000/file"

;do an initial download as a baseline control
start1 := A_NowUTC
h := curl.Init()
curl.WriteToMem(h)
curl.SetOpt("MAX_RECV_SPEED_LARGE",speed,h)
curl.SetOpt("URL",url,h)
curl.Sync(h)
end1 := A_NowUTC


;generate x number of handles
easyArr := []

loop handleCount{
	h := curl.Init()
	easyArr.push(h)
	curl.WriteToMem(,h)
	curl.SetOpt("MAX_RECV_SPEED_LARGE",speed,h)
	curl.SetOpt("URL",url,h)
}
start2 := A_NowUTC
curl.ReadyAsync(easyArr,m)
loop {
    check := 0
    check += curl.Async(m)
} until !check

end2 := A_NowUTC

t1 := DateDiff(end1,start1,"s")
t2 := DateDiff(end2,start2,"s")
diff :=  t2 - t1

results := "control: " t1 "`nscaled: " t2 "`ndifference: " diff

FileOpen(A_ScriptDir "\24.results.txt","w").Write(results)
MsgBox results