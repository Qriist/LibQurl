#requires Autohotkey v2.0
#Include <class_libcurl>

#Warn VarUnset, Off


curl := class_libcurl()

curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]

hCURL := curl._curl_easy_init()
jank := "Copyright © DotNetTutorials"
curl._curl_easy_escape(hCURL,jank)
exitapp
;msgbox hCURL
curl._curl_easy_reset(hCURL)
curl._buildOptMap()
msgbox curl.opt["URL"]["id"] "`n" 
    .   curl.opt[2]["id"] "`n" 
    .   curl.opt["CURLOPT_URL"]["id"] "`n" 
    .   curl.opt[10002]["id"]



name := "WILDCARDMATCH"
byName := curl._curl_easy_option_by_name(name)
; msgbox StrGet(NumGet(ByName,"Ptr"),"UTF-8")
; MSGBOX 
; msgbox NumGet(ByName,(floor(strlen(name)/8)+1)*8,"UInt")

;msgbox "curlDLLhandle (from LoadLibrary): " curl.curlDLLhandle "`ncurl_easy_option_by_name (from libcurl): " byName
;msgbox NumGet(byName,"Str")

exitapp
curl._curl_easy_setopt(hCURL,byName,"https://example.com")

; curl._curl_easy_setopt(hCURL,"CURLOPT_URL","https://www.google.org:80/")
msgbox curl._curl_easy_perform(hCURL)


curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]

hCURL := curl._curl_easy_init()
;msgbox hCURL
curl._curl_easy_reset(hCURL)

; msgbox curl.curl_easy_escape(hCURL,"hhttps://www.google.org")
byName := curl._curl_easy_option_by_name("URL")
msgbox StrGet(NumGet(ByName,"Ptr"),"UTF-8")


; struct curl_easyoption {
;     const char *name;
;     CURLoption id;
;     curl_easytype type;
;     unsigned int flags;
;   };

class curl_easyoption {  ; This type can also be used in a struct.
    name : uptr
    id : uint
    size => DllCall("oleaut32\SysStringByteLen", "ptr", this, "uint")
    __value {
        get => StrGet(this)
        set {
            if this.name  ; In case of use in a struct.
                this.__delete()
            this.name := DllCall("oleaut32\SysAllocStringLen", "wstr", value, "uint", StrLen(value), "ptr")
        }
    }
    __delete => DllCall("oleaut32\SysFreeString", "ptr", this)
}