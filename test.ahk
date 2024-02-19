#requires Autohotkey v2.0
#Include <class_libcurl>

#Warn VarUnset, Off


curl := class_libcurl()

curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]

curl._curl_easy_init()