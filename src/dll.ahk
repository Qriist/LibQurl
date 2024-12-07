;This file contains the low level DLL calls to interact with libcurl
;***
_curl_easy_cleanup(easy_handle) {    ;https://curl.se/libcurl/c/curl_easy_cleanup.html
    DllCall(this.curlDLLpath "\curl_easy_cleanup"
        ,   "Ptr", easy_handle)
}
_curl_easy_getinfo(easy_handle,info,&retCode) {  ;untested   https://curl.se/libcurl/c/curl_easy_getinfo.html
    static c := this.constants["CURLINFO"]
    check := DllCall(this.curlDLLpath "\curl_easy_getinfo"
        ,   "Ptr", easy_handle
        ,   "Int", c[info]["id"]
        ,   c[info]["dllType"], &retCode)
    return check
}
_curl_easy_init() {
    return DllCall(this.curlDLLpath "\curl_easy_init"
        ,   "Ptr")
}
_curl_easy_option_by_id(id) {
    ;returns from the pre-built array because it was already parsed
    If this.OptById.Has(id)
        return this.Opt[this.OptById[id]]
    return 0
    ; retCode := DllCall(this.curlDLLpath "\curl_easy_option_by_id"
    ;     ,"Int",id
    ;     ,"Ptr")
    ; return retCode
}
_curl_easy_option_by_name(name) {
    ;returns from the pre-built array because it was already parsed
    If this.Opt.Has(name)
        return this.Opt[name]
    return 0
    ; retCode := DllCall(this.curlDLLpath "\curl_easy_option_by_name"
    ;     ,"AStr",name
    ;     ,"Ptr")
    ; return retCode
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
_curl_easy_reset(easy_handle) {  ;https://curl.se/libcurl/c/curl_easy_reset.html
    DllCall(this.curlDLLpath "\curl_easy_reset"
        , "Ptr", easy_handle)
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
_curl_free(pointer) {   ;https://curl.se/libcurl/c/curl_free.html
    DllCall(this.curlDLLpath "\curl_free"
        ,   "Ptr", pointer)
}
_curl_global_init() {   ;https://curl.se/libcurl/c/curl_global_init.html
    ;can't find the various flag values so it's locked to the default "everything" mode for now - prolly okay
    if DllCall(this.curlDLLpath "\curl_global_init", "Int", 0x03, "CDecl")  ;returns 0 on success
        throw ValueError("Problem in 'curl_global_init'! Unable to init DLL!", -1, this.curlDLLpath)
    else
        return
}
_curl_multi_add_handle(multi_handle, easy_handle) { ;https://curl.se/libcurl/c/curl_multi_add_handle.html
    return DllCall(this.curlDLLpath "\curl_multi_add_handle"
        ,   "Ptr", multi_handle
        ,   "Ptr", easy_handle)
}
_curl_multi_info_read(multi_handle, &msgs_in_queue) {    ;https://curl.se/libcurl/c/curl_multi_info_read.html
    msgs_in_queue := 0
    return DllCall(this.curlDLLpath "\curl_multi_info_read"
        ,   "Int", multi_handle
        ; ,   "Int", msgs_in_queue
        ,   "Ptr*", &msgs_in_queue
        ,   "Ptr")
}
_curl_multi_init() {    ;https://curl.se/libcurl/c/curl_multi_init.html
    return DllCall(this.curlDLLpath "\curl_multi_init"
        ,   "Ptr")
}
_curl_multi_perform(multi_handle, &running_handles) {    ;https://curl.se/libcurl/c/curl_multi_perform.html
    running_handles := 0    ;required allocation
    ret := DllCall(this.curlDLLpath "\curl_multi_perform"
        ,   "Ptr", multi_handle
        ,   "Ptr*", &running_handles)
    return ret
}
_curl_multi_remove_handle(multi_handle, easy_handle) {   ;https://curl.se/libcurl/c/curl_multi_remove_handle.html
    return DllCall(this.curlDLLpath "\curl_multi_remove_handle"
        ,   "Int", multi_handle
        ,   "Int", easy_handle)
}
_curl_slist_append(ptrSList,strArrayItem) { ;https://curl.se/libcurl/c/curl_slist_append.html
    return DllCall(this.curlDLLpath "\curl_slist_append"
        , "Ptr" , ptrSList
        , "AStr", strArrayItem
        , "Ptr")
}
_curl_slist_free_all(ptrSList) {    ;https://curl.se/libcurl/c/curl_slist_free_all.html
    return DllCall(Curl.curlDLLpath "\curl_slist_free_all"
        , "Ptr", ptrSList)
}




_curl_url() {   ;https://curl.se/libcurl/c/curl_url.html
    return DllCall(this.curlDLLpath "\curl_url")
}
_curl_url_cleanup(url_handle) {   ;https://curl.se/libcurl/c/curl_url_cleanup.html
    return DllCall(this.curlDLLpath "\curl_url_cleanup"
        ,   "Int", url_handle)
}
_curl_url_dup(url_handle) { ;https://curl.se/libcurl/c/curl_url_dup.html
    return DllCall(this.curlDLLpath "\curl_url_dup"
        ,   "Int", url_handle)
}
_curl_url_get(url_handle,part,content,flags) { ;https://curl.se/libcurl/c/curl_url_get.html
    return DllCall(this.curlDLLpath "\curl_url_get"
        ,   "Ptr", url_handle
        ,   "Int", part
        ,   "Ptr*", content
        ,   "UInt", flags)
}
_curl_url_set(url_handle,part,content,flags) {   ;https://curl.se/libcurl/c/curl_url_set.html
    return DllCall(this.curlDLLpath "\curl_url_set"
        ,   "Int", url_handle
        ,   "Int", part
        ,   "AStr", content
        ,   "UInt", flags)
}
_curl_url_strerror(errornum) {  ;https://curl.se/libcurl/c/curl_url_strerror.html
    return DllCall(this.curlDLLpath "\curl_url_strerror"
        ,   "Int", errornum
        ,   "Ptr")
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

; all dll calls below this line haven't been fully tested

_curl_easy_duphandle(easy_handle) {  ;untested   https://curl.se/libcurl/c/curl_easy_duphandle.html
    ret := DllCall(this.curlDLLpath "\curl_easy_duphandle"
        , "Int", easy_handle)
    return ret
}
_curl_easy_escape(easy_handle, url) {
    ;doesn't like unicode, should I use the native windows function for this?
    ;char *curl_easy_escape(CURL *curl, const char *string, int length);
    esc := DllCall(this.curlDLLpath "\curl_easy_escape"
        , "Ptr", easy_handle
        , "AStr", url
        , "Int", 0
        , "Ptr")
    return StrGet(esc, "UTF-8")

}

_curl_easy_header(easy_handle,name,index,origin,request,&curl_header := 0) {   ;untested https://curl.se/libcurl/c/curl_easy_header.html
    return DllCall(this.curlDLLpath "\curl_easy_header"
        ,   "Ptr", easy_handle
        ,   "Str*", name
        ,   "UPtr", index
        ,   "UInt", origin
        ,   "Int", request
        ,   "Ptr*", curl_header
        ,   "UInt")
}

_curl_easy_nextheader(easy_handle,origin,request,previous_curl_header) { ;https://curl.se/libcurl/c/curl_easy_nextheader.html
    return DllCall(this.curlDLLpath "\curl_easy_nextheader"
        ,   "Ptr", easy_handle
        ,   "UInt", origin
        ,   "Int", request
        ,   "Ptr", previous_curl_header
        ,   "Ptr")
}




_curl_easy_pause(easy_handle,bitmask) {  ;untested   https://curl.se/libcurl/c/curl_easy_pause.html
    return DllCall(this.curlDLLpath "\curl_easy_pause"
        ,   "Int", easy_handle
        ,   "UInt", bitmask)
}

_curl_easy_recv(easy_handle,buffer,buflen,&bytes) { ;untested   https://curl.se/libcurl/c/curl_easy_recv.html
    return DllCall(this.curlDLLpath "\curl_easy_recv"
        ,   "Ptr", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &bytes)
}

_curl_easy_send(easy_handle,buffer,buflen,&bytes) { ;untested   https://curl.se/libcurl/c/curl_easy_send.html
    return DllCall(this.curlDLLpath "\curl_easy_send"
        ,   "Ptr", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &bytes)
}


_curl_easy_unescape(easy_handle,input,inlength,outlength) { ;untested   https://curl.se/libcurl/c/curl_easy_unescape.html
    return DllCall(this.curlDLLpath "\curl_easy_unescape"
        ,   "Ptr", easy_handle
        ,   "AStr", input
        ,   "Int", inlength
        ,   "Int", outlength)
}
_curl_easy_upkeep(easy_handle) { ;untested https://curl.se/libcurl/c/curl_easy_upkeep.html
    return DllCall(this.curlDLLpath "\curl_easy_upkeep"
        , "Ptr", easy_handle)
}

_curl_getdate(datestring) {   ;untested   https://curl.se/libcurl/c/curl_getdate.html
    return DllCall(this.curlDLLpath "\curl_global_getdate"
        ,   "AStr", datestring
        ,   "UInt", "") ;not used, pass a NULL
}
_curl_global_cleanup(easy_handle) {  ;untested   https://curl.se/libcurl/c/curl_global_cleanup.html
    DllCall(this.curlDLLpath "\curl_global_cleanup")
}
;_curl_global_init

; _curl_global_init_mem(flags,curl_malloc_callback,curl_free_callback,curl_realloc_callback,curl_strdup_callback,curl_calloc_callback) {   ;untested   https://curl.se/libcurl/c/curl_global_init_mem.html

; }
_curl_global_sslset(id,name,&avail?) {  ;untested   https://curl.se/libcurl/c/curl_global_sslset.html
    return DllCall(this.curlDLLpath "\curl_global_sslset"
        ,   "Int", id
        ,   "AStr", name
        ,   "Ptr", &avail)
}
_curl_global_trace(config){   ;untested   https://curl.se/libcurl/c/curl_global_trace.html
    return DllCall(this.curlDLLpath "\curl_global_trace"
        ,   "AStr", config)
}
_curl_mime_addpart(mime_handle) { ;untested   https://curl.se/libcurl/c/curl_mime_addpart.html
    return DllCall(this.curlDLLpath "\curl_mime_addpart"
        ,   "Int", mime_handle)
}
_curl_mime_data(mime_handle,data,datasize) { ;untested   https://curl.se/libcurl/c/curl_mime_data.html
    return DllCall(this.curlDLLpath "\curl_mime_data"
        ,   "Int", mime_handle
        ,   "Ptr", data
        ,   "Int", datasize)
}
_curl_mime_data_cb(mime_handle,datasize,readfunc,seekfunc,freefunc,arg) {  ;untested   https://curl.se/libcurl/c/curl_mime_data_cb.html
    return DllCall(this.curlDLLpath "\curl_mime_data_cb"
        ,   "Int", mime_handle
        ,   "Int", datasize
        ,   "Ptr", readfunc
        ,   "Ptr", seekfunc
        ,   "Ptr", freefunc
        ,   "Ptr", arg)
}
_curl_mime_encoder(mime_handle,encoding) {  ;untested   https://curl.se/libcurl/c/curl_mime_encoder.html
    return DllCall(this.curlDLLpath "\curl_mime_encoder"
        ,   "Int", mime_handle
        ,   "AStr", encoding)
}
_curl_mime_filedata(mime_handle,filename) {    ;untested   https://curl.se/libcurl/c/curl_mime_filedata.html
    return DllCall(this.curlDLLpath "\curl_mime_filedata"
        ,   "Int", mime_handle
        ,   "AStr", filename)
}
_curl_mime_filename(mime_handle,filename) { ;untested   https://curl.se/libcurl/c/curl_mime_filename.html
    return DllCall(this.curlDLLpath "\curl_mime_filename"
        ,   "Int", mime_handle
        ,   "AStr", filename)
}
_curl_mime_free(mime_handle) {  ;untested   https://curl.se/libcurl/c/curl_mime_free.html
    return DllCall(this.curlDLLpath "curl_mime_free"
        ,   "Int", mime_handle)
}
_curl_mime_headers(mime_handle,headers,take_ownership) {    ;untested   https://curl.se/libcurl/c/curl_mime_headers.html
    return DllCall(this.curlDLLpath "curl_mime_headers"
        ,   "Int", mime_handle
        ,   "Int", headers
        ,   "Int", take_ownership)
}
_curl_mime_init(easy_handle) {  ;untested   https://curl.se/libcurl/c/curl_mime_init.html
    /*  use the mime interface in place of the following depreciated functions:
        curl_formadd
        curl_formfree
        curl_formget
    */
    return DllCall(this.curlDLLpath "\curl_mime_init"
        ,   "Int", easy_handle
        ,   "Ptr")
}
_curl_mime_name(mime_handle,name) { ;untested   https://curl.se/libcurl/c/curl_mime_name.html
    return DllCall(this.curlDLLpath "\curl_mime_name"
        ,   "Int", mime_handle
        ,   "AStr", name)
}
_curl_mime_subparts(mime_handle,mime_part) {  ;untested   https://curl.se/libcurl/c/curl_mime_subparts.html
    return DllCall(this.curlDLLpath "\curl_mime_subparts"
        ,   "Int", mime_handle
        ,   "Int", mime_part)
}
_curl_mime_type(mime_part,mimetype) {   ;untested   https://curl.se/libcurl/c/curl_mime_type.html
    return DllCall(this.curlDLLpath "\curl_mime_type"
        ,   "Int", mime_part
        ,   "AStr", mimetype)
}

_curl_multi_assign(multi_handle,sockfd,sockptr) {   ;untested   https://curl.se/libcurl/c/curl_multi_assign.html
    return DllCall(this.curlDLLpath "\curl_multi_assign"
        ,   "Int", multi_handle
        ,   "Int", sockfd
        ,   "Ptr", sockptr)
}
_curl_multi_cleanup(multi_handle) { ;untested   https://curl.se/libcurl/c/curl_multi_cleanup.html
    return DllCall(this.curlDLLpath "\curl_multi_cleanup"
        ,   "Int", multi_handle)
}
_curl_multi_fdset(multi_handle,read_fd_set,write_fd_set,exc_fd_set,max_fd) {    ;untested   https://curl.se/libcurl/c/curl_multi_fdset.html
    return DllCall(this.curlDLLpath "\curl_multi_fdset"
        ,   "Ptr", read_fd_set
        ,   "Ptr", write_fd_set
        ,   "Ptr", exc_fd_set
        ,   "Int", max_fd)
}
_curl_multi_get_handles(multi_handle) { ;untested   https://curl.se/libcurl/c/curl_multi_get_handles.html
    return DllCall(this.curlDLLpath "\curl_multi_get_handles"
        ,   "Int", multi_handle
        ,   "Ptr")
}

_curl_multi_setopt(multi_handle, option, parameter) {  ;untested   https://curl.se/libcurl/c/curl_multi_setopt.html
    return DllCall(this.curlDLLpath "\_curl_multi_setopt"
        ,   "Int", multi_handle
        ,   "Int", option
        ,   paramType?, parameter)   ;TODO - build multi opt map
}
_curl_multi_socket_action(multi_handle,sockfd,ev_bitmask,running_handles) {   ;untested   https://curl.se/libcurl/c/curl_multi_socket_action.html
    return DllCall(this.curlDLLpath "\curl_multi_socket_action"
        ,   "Int", multi_handle
        ,   "Int", sockfd
        ,   "Int", ev_bitmask
        ,   "Int", running_handles)
}
_curl_multi_strerror(errornum) {    ;untested   https://curl.se/libcurl/c/curl_multi_strerror.html
    return DllCall(this.curlDLLpath "\curl_multi_strerror"
        ,   "Int", errornum
        ,   "Ptr")
}
_curl_multi_timeout(multi_handle,timeout) { ;untested   https://curl.se/libcurl/c/curl_multi_timeout.html
    return DllCall(this.curlDLLpath "curl_multi_timeout"
        ,   "Int", multi_handle
        ,   "Int", timeout)
}
_curl_multi_poll(multi_handle,extra_fds,extra_nfds,timeout_ms,&numfds) {    ;untested   https://curl.se/libcurl/c/curl_multi_poll.html
    return DllCall(this.curlDLLpath "curl_multi_poll"
        ,   "Ptr", multi_handle
        ,   "Ptr", extra_fds
        ,   "UInt", extra_nfds
        ,   "Int", timeout_ms
        ,   "Ptr", &numfds)
}
_curl_multi_wait(multi_handle, extra_fds, extra_nfds, timeout_ms, numfds) {    ;untested   https://curl.se/libcurl/c/curl_multi_wait.html
    return DllCall(this.curlDLLpath "\curl_multi_wait"
        ,   "Ptr", multi_handle
        ,   "Ptr", extra_fds
        ,   "UInt", extra_nfds
        ,   "Int", timeout_ms
        ,   "Ptr", numfds)
}
_curl_multi_wakeup(multi_handle) {  ;untested   https://curl.se/libcurl/c/curl_multi_wakeup.html
    return DllCall(this.curlDLLpath "\curl_multi_wakeup"
        ,   "Int", multi_handle)
}
_curl_pushheader_byname(headerStruct, name) { ;untested   https://curl.se/libcurl/c/curl_pushheader_byname.html
    return DllCall(this.curlDLLpath "\curl_pushheader_byname"
        ,   "Ptr", headerStruct
        ,   "AStr", name
        ,   "Ptr")
}
_curl_pushheader_bynum(headerStruct, num) { ;untested   https://curl.se/libcurl/c/curl_pushheader_bynum.html
    return DllCall(this.curlDLLpath "\curl_pushheader_bynum"
        ,   "Ptr", headerStruct
        ,   "Int", num
        ,   "Ptr")
}
_curl_share_cleanup(share_handle) { ;untested   https://curl.se/libcurl/c/curl_share_cleanup.html
    return DllCall(this.curlDLLpath "\curl_share_cleanup"
        ,   "Int", share_handle)
}
_curl_share_init() {    ;untested   https://curl.se/libcurl/c/curl_share_init.html
    return DllCall(this.curlDLLpath "\curl_share_init"
        ,   "Ptr")
}
_curl_share_setopt(share_handle,option,parameter) { ;untested   https://curl.se/libcurl/c/curl_share_setopt.html
    return DllCall(this.curlDLLpath "\curl_share_setopt"
        ,   "Int", share_handle
        ,   "Int", option
        ,   paramType?, parameter)   ;TODO - build share opt map
}
_curl_share_strerror(errornum) {    ;untested   https://curl.se/libcurl/c/curl_share_strerror.html
    return DllCall(this.curlDLLpath "\curl_share_strerror"
        ,   "Int", errornum
        ,   "Ptr")
}


_curl_ws_recv(easy_handle,buffer,buflen,&recv,&meta) {   ;untested   https://curl.se/libcurl/c/curl_ws_recv.html
    return DllCall(this.curlDLLpath "\curl_ws_recv"
        ,   "Int", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &recv
        ,   "Ptr", meta)
}
_curl_ws_send(easy_handle,buffer,buflen,&sent,fragsize,flags) { ;untested   https://curl.se/libcurl/c/curl_ws_send.html
    return DllCall(this.curlDLLpath "\curl_ws_send"
        ,   "Int", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &sent
        ,   "Int", fragsize
        ,   "UInt", flags)
}
_curl_ws_meta(easy_handle) {    ;untested   https://curl.se/libcurl/c/curl_ws_meta.html
    return DllCall(this.curlDLLpath "\curl_version_info"
        , "Int", easy_handle
        , "Ptr")
}


