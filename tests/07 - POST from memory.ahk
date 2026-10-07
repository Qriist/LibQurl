#Requires AutoHotKey v2.1-
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

postUrl := "https://httpbin.org/post" ;site we're POSTing to
curl.SetOpt("URL", postUrl)

;simple POSTs without setting mime_type

postSource := 1234567890
curl.SetPost(postSource)
curl.WriteToFile(A_ScriptDir "\07.integer.json")
curl.Sync()

postSource := "abcdefghij"
curl.SetPost(postSource)
curl.WriteToFile(A_ScriptDir "\07.string.json")
curl.Sync()

postSource := { ObjectToDump: "dummyValue1" }
curl.SetPost(postSource)
curl.WriteToFile(A_ScriptDir "\07.object.json")
curl.Sync()

postSource := ["ArrayToDump", "dummyValue2"]
curl.SetPost(postSource)
curl.WriteToFile(A_ScriptDir "\07.array.json")
curl.Sync()

;the rest demonstrate explicitly setting mime_type
headerObj := Map()  ;reusable

postSource := Map("MapToDump", "dummyValue3")
mime_type := curl.SetPost(postSource)
headerObj["Content-Type"] := mime_type
curl.SetHeaders(headerObj)
curl.WriteToFile(A_ScriptDir "\07.map.json")
curl.Sync()

postSource := Buffer(17, 81) ;17 Q's
mime_type := curl.SetPost(postSource)
headerObj["Content-Type"] := mime_type
curl.SetHeaders(headerObj)
curl.WriteToFile(A_ScriptDir "\07.buffer.json")
curl.Sync()

postSource := FileOpen(A_ScriptDir "\07.binary.upload.zip", "r")
mime_type := curl.SetPost(postSource)
headerObj["Content-Type"] := mime_type
curl.SetHeaders(headerObj)
curl.WriteToFile(A_ScriptDir "\07.binary.json")
curl.Sync()