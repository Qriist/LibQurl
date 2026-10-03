#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")
url := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-07.pgn.zst"

curl.SetOpt("URL", url)

main := Gui(, "SimSync test")
main.AddButton("w200", "Download via Sync").OnEvent("Click", DownloadSync)
main.AddButton("w200", "Download via SimSync").OnEvent("Click", DownloadSimSync)
main.AddButton("xm w200", "Click while downloading either").OnEvent("Click", (*) => MsgBox("Ping"))
main.Show()

DownloadSimSync(*) {
    ToolTip("Downloading SimSync")
    curl.WriteToFile(A_ScriptDir "\26 - using SimSync.SimSync.bin")

    curl.SimSync()
    ToolTip()

    easy_handle := curl.easyHandleMap[0][1]
    info := curl.PrintObj(curl.easyHandleMap[easy_handle]["lastMultiInfo"])
    MsgBox("SimSync finished.`n`n" info)
}
DownloadSync(*) {
    ToolTip("Downloading Sync")
    curl.WriteToFile(A_ScriptDir "\26 - using SimSync.Sync.bin")

    curl.Sync()

    ToolTip()
    MsgBox("Sync finished.")
}
