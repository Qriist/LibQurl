#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;test gzip
url := "https://www.titsandasses.org"
;url := "https://database.lichess.org/threeCheck/lichess_db_threeCheck_rated_2024-10.pgn.zst"
curl.SetOpt("URL",url)
curl.HeaderToFile(A_ScriptDir "\02.gzip.header.txt")
curl.WriteToFile(A_ScriptDir "\02.gzip.body.html")
curl.Sync()

;test brotli
url := "https://db.ygoprodeck.com/api/v7/checkDBVer.php"
curl.SetOpt("URL",url)
curl.HeaderToFile(A_ScriptDir "\02.brotli.header.txt")
curl.WriteToFile(A_ScriptDir "\02.brotli.body.json")
curl.Sync()
