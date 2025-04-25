#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;define test files
lichess := "https://database.lichess.org/standard/lichess_db_standard_rated_"
under_threshold     := lichess "2013-01.pgn.zst"   ;17mb
normal_threshold    := lichess "2013-10.pgn.zst"   ;63mb
reduced_threshold   := lichess "2013-07.pgn.zst"   ;43mb
increased_threshold := lichess "2013-12.pgn.zst"   ;92mb

;file is small enough to download to default memory constraint (50mb limit)
url := under_threshold
curl.SetOpt("URL",url)
curl.WriteToMagic()
curl.Sync()

;file is large enough to trigger temp file disk flush
url := normal_threshold
curl.SetOpt("URL",url)
curl.WriteToMagic()
curl.Sync()

;file is larger than a modified memory constraint
url := reduced_threshold
curl.SetOpt("URL",url)
curl.WriteToMagic(1024**2*25)
curl.Sync()

;file is smaller than a modified memory constrain
url := increased_threshold
curl.SetOpt("URL",url) 
curl.WriteToMagic(1024**2*100)
curl.Sync()