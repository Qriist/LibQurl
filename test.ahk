#requires Autohotkey v2.0
#Include <class_libcurl>

#Warn VarUnset, Off


curl := class_libcurl()

curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]

hCURL := curl._curl_easy_init()
;msgbox hCURL
;curl._curl_easy_reset(hCURL)
curl._curl_easy_setopt(hCURL,"CURLOPT_URL","https://titsandasses.org/")