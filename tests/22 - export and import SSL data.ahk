#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;pulls the default handle if you don't want to manage an entire instance
share_handle := curl.shareHandleMap[0][1]
curl.ShareSetOpt("SHARE","SSL_SESSION")

;Add the share_handle to the current easy_handle.
;This must be done before executing a transfer.
curl.SetOpt("SHARE",share_handle)

;if you had previously saved ssl data now is the time to
;import all tickets found in the sslObj.
; curl.ImportSSLs(sslObj)

;Execute the transfer to generate SSL data.
url := "https://curl.se/"
curl.SetOpt("URL",url)
curl.Sync()

;SSL data is now available to be exported.
sslObj := curl.ExportSSLs()

;Example of dumping to json to store/restore the data.
sslJson := JSON.Dump(sslObj)
sslObj := JSON.Load(sslJson)

FileOpen(a_scriptdir "\22.results.txt","w").Write(sslJson)