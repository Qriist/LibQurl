;This file contains the low level DLL calls to interact with libcurl
;***
_curl_easy_cleanup(easy_handle) {    ;https://curl.se/libcurl/c/curl_easy_cleanup.html
    static curl_easy_cleanup := this._getDllAddress(this.curlDLLpath,"curl_easy_cleanup") 
    return DllCall(curl_easy_cleanup
        ,   "Ptr", easy_handle)
}
_curl_easy_duphandle(easy_handle) {  ;https://curl.se/libcurl/c/curl_easy_duphandle.html
    ;technically unused by the class
    static curl_easy_duphandle := this._getDllAddress(this.curlDLLpath,"curl_easy_duphandle")
    ret := DllCall(this.curlDLLpath "\curl_easy_duphandle"
        , "Int", easy_handle)
    return ret
}
_curl_easy_getinfo(easy_handle,info,&retCode) {  ;https://curl.se/libcurl/c/curl_easy_getinfo.html
    static c := this.constants["CURLINFO"]
    static curl_easy_getinfo := this._getDllAddress(this.curlDLLpath,"curl_easy_getinfo") 
    return DllCall(curl_easy_getinfo
        ,   "Ptr", easy_handle
        ,   "Int", c[info]["id"]
        ,   c[info]["dllType"], &retCode)
}
_curl_easy_header(easy_handle,name,index,origin,request,&curl_header := 0) {   ;https://curl.se/libcurl/c/curl_easy_header.html
    static curl_easy_header := this._getDllAddress(this.curlDLLpath,"curl_easy_header") 
    return DllCall(curl_easy_header
        ,   "Ptr", easy_handle
        ,   "AStr", name
        ,   "Ptr", index
        ,   "UInt", origin
        ,   "Int", request
        ,   "Ptr*", &curl_header
        ,   "UInt")
}
_curl_easy_init() {
    static curl_easy_init := this._getDllAddress(this.curlDLLpath,"curl_easy_init") 
    return DllCall(curl_easy_init
        ,   "Ptr")
}
_curl_easy_nextheader(easy_handle,origin,request,previous_curl_header) { ;https://curl.se/libcurl/c/curl_easy_nextheader.html
    static curl_easy_nextheader := this._getDllAddress(this.curlDLLpath,"curl_easy_nextheader")
    return DllCall(curl_easy_nextheader
        ,   "Ptr", easy_handle
        ,   "UInt", origin
        ,   "Int", request
        ,   "Ptr", previous_curl_header
        ,   "Ptr")
}
_curl_easy_option_by_id(id) {
    ;returns from the pre-built array because it was already parsed
    If this.OptById.Has(id)
        return this.Opt[this.OptById[id]]
    return 0
    ; static curl_easy_option_by_id := this._getDllAddress(this.curlDLLpath,"curl_easy_option_by_id") 
    ; retCode := DllCall(curl_easy_option_by_id
    ;     ,"Int",id
    ;     ,"Ptr")
    ; return retCode
}
_curl_easy_option_by_name(name) {
    ;returns from the pre-built array because it was already parsed
    If this.Opt.Has(name)
        return this.Opt[name]
    return 0
    ; static curl_easy_option_by_name := this._getDllAddress(this.curlDLLpath,"curl_easy_option_by_name") 
    ; retCode := DllCall(curl_easy_option_by_name
        ; ,"AStr",name
        ; ,"Ptr")
    ; return retCode
}
_curl_easy_option_next(optPtr) {    ;https://curl.se/libcurl/c/curl_easy_option_next.html
    static curl_easy_option_next := this._getDllAddress(this.curlDLLpath,"curl_easy_option_next") 
    return DllCall(curl_easy_option_next
        ,   "UInt", optPtr
        ,   "Ptr")
}
_curl_easy_pause(easy_handle,bitmask) {  ;https://curl.se/libcurl/c/curl_easy_pause.html
    static curl_easy_pause := this._getDllAddress(this.curlDLLpath,"curl_easy_pause") 
    return DllCall(curl_easy_pause
        ,   "Int", easy_handle
        ,   "UInt", bitmask)
}
_curl_easy_perform(easy_handle?) {
    easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
    static curl_easy_perform := this._getDllAddress(this.curlDLLpath,"curl_easy_perform")
    return DllCall(curl_easy_perform
        ,   "Ptr", easy_handle
        ,   "Ptr")
}
_curl_easy_reset(easy_handle) {  ;https://curl.se/libcurl/c/curl_easy_reset.html
    static curl_easy_reset := this._getDllAddress(this.curlDLLpath,"curl_easy_reset") 
    return DllCall(curl_easy_reset
        , "Ptr", easy_handle)
}
_curl_easy_recv(easy_handle,dataBuffer,buflen,&bytes := 0) { ;https://curl.se/libcurl/c/curl_easy_recv.html
    static curl_easy_recv := this._getDllAddress(this.curlDLLpath,"curl_easy_recv") 
    return DllCall(curl_easy_recv
        ,   "Ptr", easy_handle
        ,   "Ptr", dataBuffer
        ,   "Int", buflen
        ,   "Int*", &bytes)
}
_curl_easy_send(easy_handle,dataBuffer,buflen,&bytes := 0) { ;https://curl.se/libcurl/c/curl_easy_send.html
    static curl_easy_send := this._getDllAddress(this.curlDLLpath,"curl_easy_send") 
    return DllCall(curl_easy_send
        ,   "Ptr", easy_handle
        ,   "Ptr", dataBuffer
        ,   "Int", buflen
        ,   "Int*", &bytes)
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
    static curl_easy_setopt := this._getDllAddress(this.curlDLLpath,"curl_easy_setopt") 
    return DllCall(curl_easy_setopt
        ,   "Ptr", easy_handle
        ,   "Int", this.opt[option]["id"]
        ,   this.opt[option]["type"], parameter)
}
_curl_easy_strerror(errornum) {
    static curl_easy_strerror := this._getDllAddress(this.curlDLLpath,"curl_easy_strerror") 
    return DllCall(curl_easy_strerror
        , "Int", errornum
        ,"Ptr")
}
_curl_easy_upkeep(easy_handle) { ;https://curl.se/libcurl/c/curl_easy_upkeep.html
    static curl_easy_upkeep := this._getDllAddress(this.curlDLLpath,"curl_easy_upkeep") 
    return DllCall(curl_easy_upkeep
        , "Ptr", easy_handle)
}
_curl_free(pointer) {   ;https://curl.se/libcurl/c/curl_free.html
    static curl_free := this._getDllAddress(this.curlDLLpath,"curl_free") 
    DllCall(curl_free
        ,   "Ptr", pointer)
}
_curl_global_init() {   ;https://curl.se/libcurl/c/curl_global_init.html
    ;can't find the various flag values so it's locked to the default "everything" mode for now - prolly okay
    static curl_global_init := this._getDllAddress(this.curlDLLpath,"curl_global_init") 
    if DllCall(curl_global_init, "Int", 0x03, "CDecl")  ;returns 0 on success
        throw ValueError("Problem in 'curl_global_init'! Unable to init DLL!", -1, this.curlDLLpath)
    else
        return
}
_curl_global_sslset(id,name,&avail := 0) {  ;https://curl.se/libcurl/c/curl_global_sslset.html
    static curl_global_sslset := this._getDllAddress(this.curlDLLpath,"curl_global_sslset") 
    return DllCall(curl_global_sslset
        ,   "UInt", id
        ,   "AStr", name
        ,   "Ptr*", &avail := 0)
}
_curl_multi_add_handle(multi_handle, easy_handle) { ;https://curl.se/libcurl/c/curl_multi_add_handle.html
    static curl_multi_add_handle := this._getDllAddress(this.curlDLLpath,"curl_multi_add_handle") 
    return DllCall(curl_multi_add_handle
        ,   "Ptr", multi_handle
        ,   "Ptr", easy_handle)
}
_curl_multi_info_read(multi_handle, &msgs_in_queue) {    ;https://curl.se/libcurl/c/curl_multi_info_read.html
    static curl_multi_info_read := this._getDllAddress(this.curlDLLpath,"curl_multi_info_read") 
    msgs_in_queue := 0
    return DllCall(curl_multi_info_read
        ,   "Int", multi_handle
        ; ,   "Int", msgs_in_queue
        ,   "Ptr*", &msgs_in_queue
        ,   "Ptr")
}
_curl_multi_init() {    ;https://curl.se/libcurl/c/curl_multi_init.html
    static curl_multi_init := this._getDllAddress(this.curlDLLpath,"curl_multi_init") 
    return DllCall(curl_multi_init
        ,   "Ptr")
}
_curl_multi_perform(multi_handle, &running_handles) {    ;https://curl.se/libcurl/c/curl_multi_perform.html
    static curl_multi_perform := this._getDllAddress(this.curlDLLpath,"curl_multi_perform") 
    running_handles := 0    ;required allocation
    return DllCall(curl_multi_perform
        ,   "Ptr", multi_handle
        ,   "Ptr*", &running_handles)
}
_curl_multi_remove_handle(multi_handle, easy_handle) {   ;https://curl.se/libcurl/c/curl_multi_remove_handle.html
    static curl_multi_remove_handle := this._getDllAddress(this.curlDLLpath,"curl_multi_remove_handle") 
    return DllCall(curl_multi_remove_handle
        ,   "Int", multi_handle
        ,   "Int", easy_handle)
}
_curl_slist_append(ptrSList,strArrayItem) { ;https://curl.se/libcurl/c/curl_slist_append.html
    static curl_slist_append := this._getDllAddress(this.curlDLLpath,"curl_slist_append") 
    return DllCall(curl_slist_append
        , "Ptr" , ptrSList
        , "AStr", strArrayItem
        , "Ptr")
}
_curl_slist_free_all(ptrSList) {    ;https://curl.se/libcurl/c/curl_slist_free_all.html
    static curl_slist_free_all := this._getDllAddress(this.curlDLLpath,"curl_slist_free_all") 
    return DllCall(curl_slist_free_all
        , "Ptr", ptrSList)
}




_curl_url() {   ;https://curl.se/libcurl/c/curl_url.html
    /*  use the URL interface instead of the following deprecated functions:
        curl_easy_escape
        curl_easy_unescape
        curl_escape
        curl_unescape
    */
    static curl_url := this._getDllAddress(this.curlDLLpath,"curl_url") 
    return DllCall(curl_url)
}
_curl_url_cleanup(url_handle) {   ;https://curl.se/libcurl/c/curl_url_cleanup.html
    static curl_url_cleanup := this._getDllAddress(this.curlDLLpath,"curl_url_cleanup") 
    return DllCall(curl_url_cleanup
        ,   "Int", url_handle)
}
_curl_url_dup(url_handle) { ;https://curl.se/libcurl/c/curl_url_dup.html
    static curl_url_dup := this._getDllAddress(this.curlDLLpath,"curl_url_dup") 
    return DllCall(curl_url_dup
        ,   "Int", url_handle)
}
_curl_url_get(url_handle,part,content,flags) { ;https://curl.se/libcurl/c/curl_url_get.html
    static curl_url_get := this._getDllAddress(this.curlDLLpath,"curl_url_get") 
    return DllCall(curl_url_get
        ,   "Ptr", url_handle
        ,   "Int", part
        ,   "Ptr*", content
        ,   "UInt", flags)
}
_curl_url_set(url_handle,part,content,flags) {   ;https://curl.se/libcurl/c/curl_url_set.html
    static curl_url_set := this._getDllAddress(this.curlDLLpath,"curl_url_set") 
    return DllCall(curl_url_set
        ,   "Int", url_handle
        ,   "Int", part
        ,   "AStr", content
        ,   "UInt", flags)
}
_curl_url_strerror(errornum) {  ;https://curl.se/libcurl/c/curl_url_strerror.html
    static curl_url_strerror := this._getDllAddress(this.curlDLLpath,"curl_url_strerror") 
    return DllCall(curl_url_strerror
        ,   "Int", errornum
        ,   "Ptr")
}
_curl_version() {   ;https://curl.se/libcurl/c/curl_version.html
    static curl_version := this._getDllAddress(this.curlDLLpath,"curl_version") 
    return StrGet(DllCall(curl_version
        ,   "char", 0
        ,   "Ptr")  ;return a ptr from DllCall
        ,   "UTF-8")
}
_curl_version_info() {  ;https://curl.se/libcurl/c/curl_version_info.html
    ;returns run-time libcurl version info
    static curl_version_info := this._getDllAddress(this.curlDLLpath,"curl_version_info") 
    return DllCall(curl_version_info
        ,   "Int", 0xA
        ,   "Ptr")
}

; all dll calls below this line haven't been fully tested

_curl_getdate(datestring) {   ;untested   https://curl.se/libcurl/c/curl_getdate.html
    static curl_getdate := this._getDllAddress(this.curlDLLpath,"curl_getdate") 
    return DllCall(curl_getdate
        ,   "AStr", datestring
        ,   "UInt", "") ;not used, pass a NULL
}
_curl_global_cleanup() {  ;untested   https://curl.se/libcurl/c/curl_global_cleanup.html
    static curl_global_cleanup := this._getDllAddress(this.curlDLLpath,"curl_global_cleanup") 
    DllCall(curl_global_cleanup)    ;no return value
}
;_curl_global_init

; _curl_global_init_mem(flags,curl_malloc_callback,curl_free_callback,curl_realloc_callback,curl_strdup_callback,curl_calloc_callback) {   ;untested   https://curl.se/libcurl/c/curl_global_init_mem.html
    ; static curl_global_init_mem := this._getDllAddress(this.curlDLLpath,"curl_global_init_mem") 
    ; return DllCall(curl_global_init_mem
; }
_curl_global_trace(config){   ;untested   https://curl.se/libcurl/c/curl_global_trace.html
    static curl_global_trace := this._getDllAddress(this.curlDLLpath,"curl_global_trace") 
    return DllCall(curl_global_trace
        ,   "AStr", config)
}
_curl_mime_addpart(mime_handle) { ;untested   https://curl.se/libcurl/c/curl_mime_addpart.html
    static curl_mime_addpart := this._getDllAddress(this.curlDLLpath,"curl_mime_addpart") 
    return DllCall(curl_mime_addpart
            ,   "Int", mime_handle)
}
_curl_mime_data(mime_handle,data,datasize) { ;untested   https://curl.se/libcurl/c/curl_mime_data.html
    static curl_mime_data := this._getDllAddress(this.curlDLLpath,"curl_mime_data") 
    return DllCall(curl_mime_data
        ,   "Int", mime_handle
        ,   "Ptr", data
        ,   "Int", datasize)
}
_curl_mime_data_cb(mime_handle,datasize,readfunc,seekfunc,freefunc,arg) {  ;untested   https://curl.se/libcurl/c/curl_mime_data_cb.html
    static curl_mime_data_cb := this._getDllAddress(this.curlDLLpath,"curl_mime_data_cb") 
    return DllCall(curl_mime_data_cb
        ,   "Int", mime_handle
        ,   "Int", datasize
        ,   "Ptr", readfunc
        ,   "Ptr", seekfunc
        ,   "Ptr", freefunc
        ,   "Ptr", arg)
}
_curl_mime_encoder(mime_handle,encoding) {  ;untested   https://curl.se/libcurl/c/curl_mime_encoder.html
    static curl_mime_encoder := this._getDllAddress(this.curlDLLpath,"curl_mime_encoder") 
    return DllCall(curl_mime_encoder
        ,   "Int", mime_handle
        ,   "AStr", encoding)
}
_curl_mime_filedata(mime_handle,filename) {    ;untested   https://curl.se/libcurl/c/curl_mime_filedata.html
    static curl_mime_filedata := this._getDllAddress(this.curlDLLpath,"curl_mime_filedata") 
    return DllCall(curl_mime_filedata
        ,   "Int", mime_handle
        ,   "AStr", filename)
}
_curl_mime_filename(mime_handle,filename) { ;untested   https://curl.se/libcurl/c/curl_mime_filename.html
    static curl_mime_filename := this._getDllAddress(this.curlDLLpath,"curl_mime_filename") 
    return DllCall(curl_mime_filename
        ,   "Int", mime_handle
        ,   "AStr", filename)
}
_curl_mime_free(mime_handle) {  ;untested   https://curl.se/libcurl/c/curl_mime_free.html
    static curl_mime_free := this._getDllAddress(this.curlDLLpath,"curl_mime_free") 
    return DllCall(curl_mime_free
        ,   "Int", mime_handle)
}
_curl_mime_headers(mime_handle,headers,take_ownership) {    ;untested   https://curl.se/libcurl/c/curl_mime_headers.html
    static curl_mime_headers := this._getDllAddress(this.curlDLLpath,"curl_mime_headers") 
    return DllCall(curl_mime_headers
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
    static curl_mime_init := this._getDllAddress(this.curlDLLpath,"curl_mime_init") 
    return DllCall(curl_mime_init
        ,   "Int", easy_handle
        ,   "Ptr")
}
_curl_mime_name(mime_handle,name) { ;untested   https://curl.se/libcurl/c/curl_mime_name.html
    static curl_mime_name := this._getDllAddress(this.curlDLLpath,"curl_mime_name") 
    return DllCall(curl_mime_name
        ,   "Int", mime_handle
        ,   "AStr", name)
}
_curl_mime_subparts(mime_handle,mime_part) {  ;untested   https://curl.se/libcurl/c/curl_mime_subparts.html
    static curl_mime_subparts := this._getDllAddress(this.curlDLLpath,"curl_mime_subparts") 
    return DllCall(curl_mime_subparts
        ,   "Int", mime_handle
        ,   "Int", mime_part)
}
_curl_mime_type(mime_part,mimetype) {   ;untested   https://curl.se/libcurl/c/curl_mime_type.html
    static curl_mime_type := this._getDllAddress(this.curlDLLpath,"curl_mime_type") 
    return DllCall(curl_mime_type
        ,   "Int", mime_part
        ,   "AStr", mimetype)
}

_curl_multi_assign(multi_handle,sockfd,sockptr) {   ;untested   https://curl.se/libcurl/c/curl_multi_assign.html
    static curl_multi_assign := this._getDllAddress(this.curlDLLpath,"curl_multi_assign") 
    return DllCall(curl_multi_assign
        ,   "Int", multi_handle
        ,   "Int", sockfd
        ,   "Ptr", sockptr)
}
_curl_multi_cleanup(multi_handle) { ;untested   https://curl.se/libcurl/c/curl_multi_cleanup.html
    static curl_multi_cleanup := this._getDllAddress(this.curlDLLpath,"curl_multi_cleanup") 
    return DllCall(curl_multi_cleanup
        ,   "Int", multi_handle)
}
_curl_multi_fdset(multi_handle,read_fd_set,write_fd_set,exc_fd_set,max_fd) {    ;untested   https://curl.se/libcurl/c/curl_multi_fdset.html
    static curl_multi_fdset := this._getDllAddress(this.curlDLLpath,"curl_multi_fdset") 
    return DllCall(curl_multi_fdset
        ,   "Ptr", read_fd_set
        ,   "Ptr", write_fd_set
        ,   "Ptr", exc_fd_set
        ,   "Int", max_fd)
}
_curl_multi_get_handles(multi_handle) { ;untested   https://curl.se/libcurl/c/curl_multi_get_handles.html
    static curl_multi_get_handles := this._getDllAddress(this.curlDLLpath,"curl_multi_get_handles") 
    return DllCall(curl_multi_get_handles
        ,   "Int", multi_handle
        ,   "Ptr")
}

_curl_multi_setopt(multi_handle, option, parameter) {  ;untested   https://curl.se/libcurl/c/curl_multi_setopt.html
    static curl_multi_setopt := this._getDllAddress(this.curlDLLpath,"curl_multi_setopt") 
    return DllCall(curl_multi_setopt
        ,   "Ptr", multi_handle
        ,   "Int", this.mOpt[option]["id"]
        ,   this.mOpt[option]["dllType"], parameter)   ;TODO - build multi opt map
}
_curl_multi_socket_action(multi_handle,sockfd,ev_bitmask,running_handles) {   ;untested   https://curl.se/libcurl/c/curl_multi_socket_action.html
    static _curl_multi_socket_action := this._getDllAddress(this.curlDLLpath,"_curl_multi_socket_action") 
    return DllCall(_curl_multi_socket_action
        ,   "Int", multi_handle
        ,   "Int", sockfd
        ,   "Int", ev_bitmask
        ,   "Int", running_handles)
}
_curl_multi_strerror(errornum) {    ;untested   https://curl.se/libcurl/c/curl_multi_strerror.html
    static curl_multi_strerror := this._getDllAddress(this.curlDLLpath,"curl_multi_strerror") 
    return DllCall(curl_multi_strerror
        ,   "Int", errornum
        ,   "Ptr")
}
_curl_multi_timeout(multi_handle,timeout) { ;untested   https://curl.se/libcurl/c/curl_multi_timeout.html
    static curl_multi_timeout := this._getDllAddress(this.curlDLLpath,"curl_multi_timeout") 
    return DllCall(curl_multi_timeout
        ,   "Int", multi_handle
        ,   "Int", timeout)
}
_curl_multi_poll(multi_handle,extra_fds,extra_nfds,timeout_ms,&numfds) {    ;untested   https://curl.se/libcurl/c/curl_multi_poll.html
    static curl_multi_poll := this._getDllAddress(this.curlDLLpath,"curl_multi_poll") 
    return DllCall(curl_multi_poll
        ,   "Ptr", multi_handle
        ,   "Ptr", extra_fds
        ,   "UInt", extra_nfds
        ,   "Int", timeout_ms
        ,   "Ptr", &numfds)
}
_curl_multi_wait(multi_handle, extra_fds, extra_nfds, timeout_ms, numfds) {    ;untested   https://curl.se/libcurl/c/curl_multi_wait.html
    static curl_multi_wait := this._getDllAddress(this.curlDLLpath,"curl_multi_wait") 
    return DllCall(curl_multi_wait
        ,   "Ptr", multi_handle
        ,   "Ptr", extra_fds
        ,   "UInt", extra_nfds
        ,   "Int", timeout_ms
        ,   "Ptr", numfds)
}
_curl_multi_wakeup(multi_handle) {  ;untested   https://curl.se/libcurl/c/curl_multi_wakeup.html
    static curl_multi_wakeup := this._getDllAddress(this.curlDLLpath,"curl_multi_wakeup") 
    return DllCall(curl_multi_wakeup
        ,   "Int", multi_handle)
}
_curl_pushheader_byname(headerStruct, name) { ;untested   https://curl.se/libcurl/c/curl_pushheader_byname.html
    static curl_pushheader_byname := this._getDllAddress(this.curlDLLpath,"curl_pushheader_byname") 
    return DllCall(curl_pushheader_byname
        ,   "Ptr", headerStruct
        ,   "AStr", name
        ,   "Ptr")
}
_curl_pushheader_bynum(headerStruct, num) { ;untested   https://curl.se/libcurl/c/curl_pushheader_bynum.html
    static curl_pushheader_bynum := this._getDllAddress(this.curlDLLpath,"curl_pushheader_bynum") 
    return DllCall(curl_pushheader_bynum
        ,   "Ptr", headerStruct
        ,   "Int", num
        ,   "Ptr")
}
_curl_share_cleanup(share_handle) { ;untested   https://curl.se/libcurl/c/curl_share_cleanup.html
    static curl_share_cleanup := this._getDllAddress(this.curlDLLpath,"curl_share_cleanup") 
    return DllCall(curl_share_cleanup
            ,   "Int", share_handle)
}
_curl_share_init() {    ;untested   https://curl.se/libcurl/c/curl_share_init.html
    static curl_share_init := this._getDllAddress(this.curlDLLpath,"curl_share_init") 
    return DllCall(curl_share_init
            ,   "Ptr")
}
_curl_share_setopt(share_handle,option,parameter) { ;untested   https://curl.se/libcurl/c/curl_share_setopt.html
    return DllCall(this.curlDLLpath "\curl_share_setopt"
        ,   "Int", share_handle
        ,   "Int", option
        ,   paramType?, parameter)   ;TODO - build share opt map
}
_curl_share_strerror(errornum) {    ;untested   https://curl.se/libcurl/c/curl_share_strerror.html
    static curl_share_setopt := this._getDllAddress(this.curlDLLpath,"curl_share_setopt") 
    return DllCall(curl_share_setopt
        ,   "Int", errornum
        ,   "Ptr")
}
_curl_ws_recv(easy_handle,buffer,buflen,&recv,&meta) {   ;untested   https://curl.se/libcurl/c/curl_ws_recv.html
    static curl_ws_recv := this._getDllAddress(this.curlDLLpath,"curl_ws_recv") 
    return DllCall(curl_ws_recv
        ,   "Int", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &recv
        ,   "Ptr", meta)
}
_curl_ws_send(easy_handle,buffer,buflen,&sent,fragsize,flags) { ;untested   https://curl.se/libcurl/c/curl_ws_send.html
    static curl_ws_send := this._getDllAddress(this.curlDLLpath,"curl_ws_send") 
    return DllCall(curl_ws_send
        ,   "Int", easy_handle
        ,   "Ptr", buffer
        ,   "Int", buflen
        ,   "Int", &sent
        ,   "Int", fragsize
        ,   "UInt", flags)
}
_curl_ws_meta(easy_handle) {    ;untested   https://curl.se/libcurl/c/curl_ws_meta.html
    static curl_ws_meta := this._getDllAddress(this.curlDLLpath,"curl_ws_meta") 
    return DllCall(curl_ws_meta
        , "Int", easy_handle
        , "Ptr")
}


