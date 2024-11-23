#requires Autohotkey v2.1-alpha.2
class LibQurl {





    ; DupeInit(easy_handle?){
        ; newHandle := this._curl_easy_duphandle(easy_handle)
        ; this.easyHandleMap[newHandle] := this.easyHandleMap[0] := this.DeepClone(this.easyHandleMap[easy_handle])
        ; If !this.easyHandleMap[newHandle]
        ;     throw ValueError("Problem in 'curl_easy_duphandle'! Unable to init easy interface!", -1, this.curlDLLpath)
        ; this.easyHandleMap[newHandle] := this.easyHandleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created easy_handle
        ; ,this.easyHandleMap[newHandle]["options"] := Map()  ;prepares option storage
        ; for k,v in this.easyHandleMap[easy_handle]["options"]
        ;     this.SetOpt(k,v,newHandle)
        ; this.easyHandleMap[newHandle]["easy_handle"] := newHandle
        ; return newHandle 
        /*
        if !IsSet(easy_handle)
            easy_handle := this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        newHandle := this._curl_easy_duphandle(easy_handle)
        If !this.easyHandleMap[easy_handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)
        ; msgbox easy_handle "`n" newHandle "`n`n" this.easyHandleMap[0]["easy_handle"]
        this.easyHandleMap[newHandle] := this.DeepClone(this.easyHandleMap[easy_handle])
        msgbox this.ShowOB(this.easyHandleMap[newHandle])
        this.easyHandleMap[0]["easy_handle"] := this.easyHandleMap[newHandle]["easy_handle"]
        ; msgbox this.easyHandleMap[newHandle]["easy_handle"] "`n" this.easyHandleMap[easy_handle]["easy_handle"] "`n`n" this.easyHandleMap[0]["easy_handle"]
        ; this.easyHandleMap[newHandle] := this.easyHandleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created easy_handle
        ; ,this.easyHandleMap[newHandle]["options"] := Map()  ;prepares option storage


        ; for k,v in this.easyHandleMap[easy_handle]["options"]
        ;     this.SetOpt(k,v,newHandle)
        return newHandle   
        */     
    ; }
    GetErrorString(errornum){
        return StrGet(this._curl_easy_strerror(errornum),"UTF-8")
    }
    ListOpts(easy_handle?){  ;returns human-readable printout of the given easy_handle's set options
    easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        ret := "These are the options that have been set for this easy_handle:`n"
        for k,v in this.easyHandleMap[easy_handle]["options"]{
                if (v!="")
                    ret .= k ": " (!IsObject(v)?v:"<OBJECT>") "`n"
                else
                    ret .= k ": " "<NULL>" "`n"
        }
        return ret
    }



    SetOpts(optionMap,&optErrMap,easy_handle?){  ;for setting multiple options at once
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        optErrMap := Map()
        optErrVal := 0
        ;TODO - add handling for Opts with scaffolding
        for k,v in optionMap {
            Switch k, "OFF" {
                ; case "URL":{}
                Default: optErrVal += optErrMap[k] := this.SetOpt(k,v,easy_handle)
            }
        }
        return optErrVal    ;any non-zero value means you should check the optErrMap
    }




	
	; WriteToNone() {
	; 	Return (this._writeTo := "")
	; }

    ; WriteToMagic(easy_handle?) {
    ;     if !IsSet(easy_handle)
    ;         easy_handle := this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
    ;     ;instanstiate Storage.File
    ;     passedHandleMap := this.easyHandleMap
    ;     this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := class_libcurl.Storage.File(filename, &passedHandleMap, "body", "w", easy_handle)
    ;     this.SetOpt("WRITEDATA",this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"],easy_handle)
    ;     this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle) 
    ;     Return
    ; }
	

	

	
	; HeaderToNone() {
	; 	Return (this._headerTo := "")
	; }





 
    
    ErrorHandler(callingMethod,invokedCurlFunction,curlErrorCodeType,incomingValue?){
        If (curlErrorCodeType = "Curlcode") {

        } else if (curlErrorCodeType = "Curlmcode") {

        } else if (curlErrorCodeType = "Curlshcode") {

        } else if (curlErrorCodeType = "Curlucode") {

        } else if (curlErrorCodeType = "Curlhcode") {

        }
    }
    DeepClone(obj) {    ;https://github.com/thqby/ahk2_lib/blob/master/deepclone.ahk
        ;fully copies an object without any shared references.
        objs := Map(), objs.Default := ''
        return clone(obj)
    
        clone(obj) {
            switch Type(obj) {
                case 'Array', 'Map':
                    o := obj.Clone()
                    for k, v in o
                        if IsObject(v)
                            o[k] := objs[p := ObjPtr(v)] || (objs[p] := clone(v))
                    return o
                case 'Object':
                    o := obj.Clone()
                    for k, v in o.OwnProps()
                        if IsObject(v)
                            o.%k% := objs[p := ObjPtr(v)] || (objs[p] := clone(v))
                    return o
                default:
                    return obj
            }
        }
    }
    ; Sets custom HTTP headers for request.
	; Pass an array of "Header: value" strings OR a Map of the same.
	; Use empty value ("Header: ") to disable internally used header.
	; Use semicolon ("Header;") to add the header with no value.
	SetHeaders(headersArrayOrMap,easy_handle?) {
        if (Type(headersArrayOrMap)="Map"){
            headersArray := []
            for k,v in headersArrayOrMap{
                switch v {
                    case "":    ;diabled
                        headersArray.Push(k ": ")
                    case ";":   ;empty
                        headersArray.Push(k ";")
                    default:
                        headersArray.Push(k ": " v)
                }
            }
        } else {
            headersArray := headersArrayOrMap
        }
        headersPtr := this._ArrayToSList(headersArray)
		Return this.SetOpt("HTTPHEADER", headersPtr,easy_handle?)
	}
    	; Linked-list
	; ===========
	
	; Converts an array of strings to linked-list.
	; Returns pointer to linked-list, or 0 if something went wrong.
	
	_ArrayToSList(strArray) {
		ptrSList := 0
		ptrTemp  := 0
		
		Loop strArray.Length {
			ptrTemp := this._curl_slist_append(ptrSList,strArray[A_Index])
            
    		If (ptrTemp == 0) {
				Curl._FreeSList(ptrSList)
				Return 0
			}
			ptrSList := ptrTemp
		}
		
		Return ptrSList
	}
	
	
	; Converts linked-list to an array of strings.
	
	_SListToArray(ptrSList) {
		result  := []
		ptrNext := ptrSList
		
		Loop {
			If (ptrNext == 0)
				Break
			
			ptrData := NumGet(ptrNext, 0, "Ptr")
			ptrNext := NumGet(ptrNext, A_PtrSize, "Ptr")
			
			result.Push(StrGet(ptrData, "CP0"))
		}
		
		Return result
	}
	
	
	_FreeSList(ptrSList?) {
		If (!IsSet(ptrSList) || (ptrSList == 0))
			Return
		this._curl_slist_free_all(ptrSList)
	}


    
    ;internal libcurl functions called by this class

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
    _curl_easy_getinfo(easy_handle,info,&retCode) {  ;untested   https://curl.se/libcurl/c/curl_easy_getinfo.html
        return DllCall(this.curlDLLpath "\curl_easy_getinfo"
            ,   "Ptr", easy_handle
            ,   "UInt", info
            ,   "Int", retCode)
    }
    _curl_easy_header(easy_handle,name,index,origin,request) {   ;untested https://curl.se/libcurl/c/curl_easy_header.html
        return DllCall(this.curlDLLpath "\curl_easy_header"
            ,   "Ptr", name
            ,   "Int", index
            ,   "Int", origin
            ,   "Int", request
            ,   "Ptr")
    }

    _curl_easy_nextheader(easy_handle,origin,request,prev) { ;untested https://curl.se/libcurl/c/curl_easy_nextheader.html
        return DllCall(this.curlDLLpath "\curl_easy_nextheader"
            ,   "Int", origin
            ,   "Int", request
            ,   "Ptr", prev
            ,   "Ptr")
    }
    _curl_easy_option_by_id(id) {
        ;returns from the pre-built array
        If this.optMap.Has(id)
            return this.optMap[id]
        return 0
    }
    _curl_easy_option_by_name(name) {
        ;returns from the pre-built array
        If this.optMap.Has(name)
            return this.optMap[name]
        return 0

        ; retCode := DllCall(this.curlDLLpath "\curl_easy_option_by_name"
        ;     ,"AStr",name
        ;     ,"Ptr")
        ; return retCode
    }

    _curl_easy_pause(easy_handle,bitmask) {  ;untested   https://curl.se/libcurl/c/curl_easy_pause.html
        return DllCall(this.curlDLLpath "\curl_easy_pause"
            ,   "Int", easy_handle
            ,   "UInt", bitmask)
    }
    _curl_easy_perform(easy_handle?) {
        if !IsSet(easy_handle)
            easy_handle := this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        retCode := DllCall(this.curlDLLpath "\curl_easy_perform"
            , "Ptr", easy_handle)
        return retCode
    }
    _curl_easy_recv(easy_handle,buffer,buflen,&bytes) { ;untested   https://curl.se/libcurl/c/curl_easy_recv.html
        return DllCall(this.curlDLLpath "\curl_easy_recv"
            ,   "Ptr", easy_handle
            ,   "Ptr", buffer
            ,   "Int", buflen
            ,   "Int", &bytes)
    }
    _curl_easy_reset(easy_handle) {  ;https://curl.se/libcurl/c/curl_easy_reset.html
        DllCall(this.curlDLLpath "\curl_easy_reset"
            , "Ptr", easy_handle)
    }
    _curl_easy_send(easy_handle,buffer,buflen,&bytes) { ;untested   https://curl.se/libcurl/c/curl_easy_send.html
        return DllCall(this.curlDLLpath "\curl_easy_send"
            ,   "Ptr", easy_handle
            ,   "Ptr", buffer
            ,   "Int", buflen
            ,   "Int", &bytes)
    }

    _curl_easy_strerror(errornum) {
        return DllCall(this.curlDLLpath "\curl_easy_strerror"
            , "Int", errornum
            ,"Ptr")
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
    _curl_free(pStr) {  ;untested   ;https://curl.se/libcurl/c/curl_free.html
        DllCall("libcurl\curl_free"
            ,   "Ptr", pStr)
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
    _curl_multi_add_handle(multi_handle, easy_handle) { ;untested   https://curl.se/libcurl/c/curl_multi_add_handle.html
        return DllCall(this.curlDLLpath "\curl_multi_add_handle"
            ,   "Ptr", multi_handle
            ,   "Ptr", easy_handle)
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
        return DllCall(this.curlDLLpath "curl_multi_get_handles"
            ,   "Int", multi_handle
            ,   "Ptr")
    }
    _curl_multi_info_read(multi_handle, msgs_in_queue) {    ;untested   https://curl.se/libcurl/c/curl_multi_info_read.html
        return DllCall(this.curlDLLpath "curl_multi_info_read"
            ,   "Int", multi_handle
            ,   "Int", msgs_in_queue
            ,   "Ptr")
    }
    _curl_multi_init() {    ;untested   https://curl.se/libcurl/c/curl_multi_init.html
        return DllCall(this.curlDLLpath "curl_multi_init"
            ,   "Ptr")
    }
    _curl_multi_perform(multi_handle, running_handles) {    ;untested   https://curl.se/libcurl/c/curl_multi_perform.html
        return DllCall(this.curlDLLpath "\curl_multi_add_handle"
            ,   "Int", multi_handle
            ,   "Ptr", running_handles)
    }
    _curl_multi_remove_handle(multi_handle, easy_handle) {   ;untested   https://curl.se/libcurl/c/curl_multi_remove_handle.html
        return DllCall(this.curlDLLpath "\curl_multi_remove_handle"
            ,   "Int", multi_handle
            ,   "Int", easy_handle)
    }
    _curl_multi_setopt(multi_handle, option, parameter) {  ;untested   https://curl.se/libcurl/c/curl_multi_setopt.html
        return DllCall(this.curlDLLpath "_curl_multi_setopt"
            ,   "Int", multi_handle
            ,   "Int", option
            ,   paramType, parameter)   ;TODO - build multi opt map
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
            ,   paramType, parameter)   ;TODO - build share opt map
    }
    _curl_share_strerror(errornum) {    ;untested   https://curl.se/libcurl/c/curl_share_strerror.html
        return DllCall(this.curlDLLpath "\curl_share_strerror"
            ,   "Int", errornum
            ,   "Ptr")
    }
    _curl_slist_append(ptrSList,strArrayItem) { ;https://curl.se/libcurl/c/curl_slist_append.html
        return DllCall(this.curlDLLpath "\curl_slist_append"
            , "Ptr" , ptrSList
            , "AStr", strArrayItem
            , "Ptr")
    }
    _curl_slist_free_all(ptrSList) {    ;untested   https://curl.se/libcurl/c/curl_slist_free_all.html
        return DllCall(Curl.curlDLLpath "\curl_slist_free_all"
            , "Ptr", ptrSList)
    }
    _curl_url() {   ;untested   https://curl.se/libcurl/c/curl_url.html
        return DllCall(this.curlDLLpath "\curl_url")
    }
    _curl_url_cleanup(url_handle) {   ;untested   https://curl.se/libcurl/c/curl_url_cleanup.html
        return DllCall(this.curlDLLpath "\curl_url_cleanup"
            ,   "Int", url_handle)
    }
    _curl_url_dup(url_handle) { ;untested   https://curl.se/libcurl/c/curl_url_dup.html
        return DllCall(this.curlDLLpath "\curl_url_dup"
            ,   "Int", url_handle)
    }
    _curl_url_get(url_handle,part,content,flags) { ;untested   https://curl.se/libcurl/c/curl_url_get.html
        return DllCall(this.curlDLLpath "\curl_url_get"
            ,   "Int", url_handle
            ,   "Int", part
            ,   "AStr", content
            ,   "UInt", flags)
    }
    _curl_url_set(url_handle,part,content,flags) {   ;untested   https://curl.se/libcurl/c/curl_url_set.html
        return DllCall(this.curlDLLpath "\curl_url_set"
            ,   "Int", url_handle
            ,   "Int", part
            ,   "AStr", content
            ,   "UInt", flags)
    }
    _curl_url_strerror(errornum) {  ;untested   https://curl.se/libcurl/c/curl_url_strerror.html
        return DllCall(this.curlDLLpath "\curl_url_strerror"
            ,   "Int", errornum)
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


    StringToBase64(String, Encoding := "UTF-8")
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CRYPT_STRING_NOCRLF := 0x40000000

        Binary := Buffer(StrPut(String, Encoding))
        StrPut(String, Binary, Encoding)
        if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &Size := 0))
            throw OSError()

        Base64 := Buffer(Size << 1, 0)
        if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", Base64, "UInt*", Size))
            throw OSError()

        return StrGet(Base64)
    }
    
    }
}