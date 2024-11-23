;This file contains the low level DLL calls to interact with libcurl
;***
_curl_easy_cleanup(easy_handle) {    ;untested https://curl.se/libcurl/c/curl_easy_cleanup.html
    DllCall(this.curlDLLpath "\curl_easy_cleanup"
        ,   "Ptr", easy_handle)
}
_curl_easy_init() {
    return DllCall(this.curlDLLpath "\curl_easy_init"
        ,   "Ptr")
}

_curl_easy_option_next(optPtr) {    ;https://curl.se/libcurl/c/curl_easy_option_next.html
    return DllCall("libcurl-x64\curl_easy_option_next"
        ,   "UInt", optPtr
        ,   "Ptr")
}

_curl_easy_perform(easy_handle?) {
    easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
    retCode := DllCall(this.curlDLLpath "\curl_easy_perform"
        , "Ptr", easy_handle)
    return retCode
}
_curl_global_init() {   ;https://curl.se/libcurl/c/curl_global_init.html
    ;can't find the various flag values so it's locked to the default "everything" mode for now - prolly okay
    if DllCall(this.curlDLLpath "\curl_global_init", "Int", 0x03, "CDecl")  ;returns 0 on success
        throw ValueError("Problem in 'curl_global_init'! Unable to init DLL!", -1, this.curlDLLpath)
    else
        return
}

_curl_easy_setopt(easy_handle, option, parameter, debug?) {
    if IsSet(debug)
        msgbox this.showob(this.opt[option]) "`n`n`n"
            .   "1 passed easy_handle: " easy_handle "`n"
            .   "2 passed option id: " this.opt[option]["id"] "`n"
            .   "3 passed parameter: " (Type(parameter)="String"?parameter
                                        :Type(parameter)="Integer"?parameter
                                        :" [" Type(parameter) "]") "`n"
            .   "  passed type: " this.opt[option]["type"] "`n"
    retCode := DllCall(this.curlDLLpath "\curl_easy_setopt"
        ,   "Ptr", easy_handle
        ,   "Int", this.opt[option]["id"]
        ,   this.opt[option]["type"], parameter)
    return retCode
}

_curl_easy_strerror(errornum) {
    return DllCall(this.curlDLLpath "\curl_easy_strerror"
        , "Int", errornum
        ,"Ptr")
}
_curl_version() {   ;https://curl.se/libcurl/c/curl_version.html
    return StrGet(DllCall(this.curlDLLpath "\curl_version"
        ,   "char", 0
        ,   "Ptr")  ;return a ptr from DllCall
        ,   "UTF-8")
}
_curl_version_info() {  ;https://curl.se/libcurl/c/curl_version_info.html
    ;returns run-time libcurl version info
    return DllCall(this.curlDLLpath "\curl_version_info"
        ,   "Int", 0xA
        ,   "Ptr")
}