#Include <class_libcurl>

curl := class_libcurl()

curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

msgbox curl._curl_version()
msgbox curl._curl_version_info()