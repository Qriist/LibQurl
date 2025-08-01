﻿;This file contains the core features of LibQurl.
;Generally, anything a user might want to directly access should go here.
;leave the #compile:whatever lines at the bottom!
;when adding dependencies, use the "*i <lib>" format. It will be cleaned up by the generator.
;***
#requires Autohotkey v2.1-alpha.9
#Include "*i <Aris\G33kDude\cJson>"
#include "*i <Aris\SKAN\RunCMD>" ; SKAN/RunCMD@9a8392d
#include "*i <Aris\Qriist\libmagic>" ; github:Qriist/libmagic@v0.80.0 --main Lib\libmagic.ahk
#include "*i <Aris\Qriist\Null>" ; github:Qriist/Null@v1.0.0 --main Null.ahk
#include "*i <Aris\Chunjee\adash>"
class LibQurl {
    ;core functionality
__New(dllPath?,requestedSSLprovider?) {
    ;prepare interface maps
    this.easyHandleMap := Map()
    this.easyHandleMap[0] := []
    this.urlHandleMap := Map()
    this.urlHandleMap[0] := []
    this.multiHandleMap := Map()
    this.multiHandleMap[0] := []
    this.multiHandleMap["pending_callbacks"] := []
    this.multiHandleMap["running_callbacks"] := []
    this.shareHandleMap := Map()
    this.shareHandleMap[0] := []
    this.mimeHandleMap := Map()
    this.mimeHandleMap[0] := []
    this.mimePartMap := Map()
    this.mimePartMap[0] := []
    this.mimePartCBFcleanupArr := []

    this.unassociatedEasyHandles := Map()
    static curlDLLhandle := ""
    static curlDLLpath := ""
    this.Opt := Map()
    this.OptById := Map()
    this.mOpt := Map()
    this.mOptById := Map()
    this.struct := LibQurl._struct()  ;holds the various structs
    this.writeRefs := Map()    ;holds the various write handles
    this.constants := Map()

    this.caughtErrors := []
    this.keepLastNumErrors := 1000
    this.CURL_ERROR_SIZE := 256

    ;safely prepare curl's initial environment
    Critical "On"
    this._register(dllPath?,requestedSSLprovider?)
    this.magic := libmagic()
    Critical "Off"
}
    Init(){
        easy_handle := this._curl_easy_init()
        this.easyHandleMap[0].push(easy_handle) ;easyHandleMap[0][1] is a dynamic reference to the first created easy_handle
        this.easyHandleMap[easy_handle] := Map() 

        If !this.easyHandleMap[easy_handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)

        this.easyHandleMap[easy_handle]["easy_handle"] := easy_handle
        this.easyHandleMap[easy_handle]["options"] := Map()  ;prepares option storage
        
        ;setup error handling
        this.SetOpt("ERRORBUFFER"
            ,   this.easyHandleMap[easy_handle]["error buffer"] := Buffer(this.CURL_ERROR_SIZE))

        this.SetOpt("ACCEPT_ENCODING","",easy_handle)    ;enables compressed transfers without affecting input headers
        ; this.SetOpt("SSH_COMPRESSION",1,easy_handle)    ;enables compressed transfers without affecting input headers
        this.SetOpt("FOLLOWLOCATION",1,easy_handle)    ;allows curl to follow redirects
        this.SetOpt("MAXREDIRS",30,easy_handle)    ;limits redirects to 30 (matches recent curl default)


        ;auto-load curl's cert bundle
        ;can still be set per easy_handle
        this.SetOpt("CAINFO",this.crt??="",easy_handle)

        this.easyHandleMap[easy_handle]["callbacks"] := Map()  ;prepares write callbacks
        for k,v in ["body","header","read","progress","debug"]{
            this.easyHandleMap[easy_handle]["callbacks"][v] := Map()
            this.easyHandleMap[easy_handle]["callbacks"][v]["CBF"] := ""
        }

        this._setCallbacks(1,1,,1,,easy_handle) ;don't enable debug by default
        this.easyHandleMap[easy_handle]["debug"] := 0
        this.easyHandleMap[easy_handle]["websocket_mode"] := 0
        ; this.HeaderToMem(0,easy_handle)    ;automatically save lastHeader to memory
        
        this.easyHandleMap[easy_handle]["active_mime_handle"] := 0  ;null until set
        this.easyHandleMap[easy_handle]["associated_mime_handles"] := Map()

        return easy_handle
    }
    EasyInit(){ ;just a clarifying alias for Init()
        return this.Init()
    }
    ListHandles(){
        ;returns a plaintext listing of all handles
        ret := ""
        for k,v in this.easyHandleMap {
            ret .= k "`n"
        }
        return Trim(ret,"`n")
    }
    GetVersionInfo(){
        verPtr := this._curl_version_info()
        retObj := this.struct.curl_version_info_data(verPtr)
        return retObj
    }
    QueueOpt(option,parameter){

    }
    SetOpt(option,parameter,easy_handle?,debug?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        ;todo - move the EasyOpts to the standardized Constants array
        If this.Opt.Has(option){    ;determine if the option is known
            ;nothing to be done
        } else if InStr(option,"CURLOPT_") && this.Opt.Has(StrReplace("CURLOPT_",option)){
            option := StrReplace("CURLOPT_",option)
        } else If this.OptById.Has(option) {
            option := this.OptById[option]
        } else {
            throw ValueError("Problem in 'curl_easy_setopt'! Unknown option: " option, -1, this.curlDLLpath)
        }

        this.easyHandleMap[easy_handle]["options"][option] := parameter

        if ret := this._curl_easy_setopt(easy_handle,option,parameter,debug?)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_setopt",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        return ret
    }
    GetOpt(option,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        
        if this.easyHandleMap[easy_handle]["options"].has(option)
            return this.easyHandleMap[easy_handle]["options"][option]
        return Null()
    }
    MultiSetOpt(option,parameter,multi_handle?){
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle

        If this.mOpt.Has(option){
            ;nothing to be done
        } else if InStr(option,"CURLMOPT_") && this.mOpt.Has(StrReplace("CURLMOPT_",option)){
            option := StrReplace("CURLMOPT_",option)
        } else {
            throw ValueError("Problem in 'curl_multi_setopt'! Unknown option: " option, -1, this.curlDLLpath)
        }
        
        this.multiHandleMap[multi_handle]["options"][option] := parameter
        return this._curl_multi_setopt(multi_handle,option,parameter)
    }
    MultiGetOpt(option,multi_handle?){
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle
        
        if this.multiHandleMap[multi_handle]["options"].has(option)
            return this.multiHandleMap[multi_handle]["options"][option]
        return Null()
    }

    SetOpts(optionMap,&optErrMap?,easy_handle?){  ;for setting multiple options at once
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
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
    ListOpts(easy_handle?){  ;returns human-readable printout of the given easy_handle's set options
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        ret := "These are the options that have been set for this easy_handle:`n"
        for k,v in this.easyHandleMap[easy_handle]["options"]{
                if (v!="")
                    ret .= k ": " (!IsObject(v)?v:"<OBJECT>") "`n"
                else
                    ret .= k ": " "<NULL>" "`n"
        }
        return ret
    }
    GetErrorString(errornum){
        return StrGet(this._curl_easy_strerror(errornum),"UTF-8")
    }
    GetEasyErrorString(errornum){   ;alias for GetErrorString
        return this.GetErrorString(errornum)
    }
    GetMultiErrorString(errornum){
        return StrGet(this._curl_multi_strerror(errornum),"UTF-8")
    }
    GetShareErrorString(incomingValue){
        return StrGet(this._curl_share_strerror(incomingValue),"UTF-8")
    }
    GetUrlErrorString(incomingValue){
        return StrGet(this._curl_url_strerror(incomingValue),"UTF-8")
    }

	HeaderToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        passedHandleMap := this.easyHandleMap
		this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity := 65536, dataSize?, &passedHandleMap, "header", easy_handle)
        
        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
        Return
	}


    WriteToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "body", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle)
		Return
	}

	HeaderToFile(filename, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "header", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
		Return
	}

    WriteToFile(filename, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "body", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle) 
        Return
    }
    WriteToMagic(flushThreshold := (1024 ** 2 * 50), easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        passedHandleMap := this.easyHandleMap

        ;predetermine the file to dump to if flushThreshold is reached
        flushFilename := A_Temp "\LibQurl\" A_NowUTC "." easy_handle

        body := this.easyHandleMap[easy_handle]["callbacks"]["body"]
        body["storageHandle"] := LibQurl.Storage.Magic(flushFilename, flushThreshold, &passedHandleMap, "body", easy_handle)

        writeHandle := body["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",body["CBF"],easy_handle) 
        Return
    }
    ReadyAsync(inEasyHandles?,multi_handle?){    ;Add any number of easy_handles to the multi pool. Accepts integers or object.
        inEasyHandles ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle

        If (Type(inEasyHandles) = "Integer")
            inEasyHandles := [inEasyHandles]
        for k,v in (Type(inEasyHandles)!="Object"?inEasyHandles:inEasyHandles.OwnProps()) { ;itemize Objects if required
            this._fallbackWrite(v)
            this.AddEasyToMulti(v,multi_handle)
        }
    }
    Async(multi_handle?){
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle

        ;tell curl to process the downloads
        retCode := this._curl_multi_perform(multi_handle,&still_running)

        ;check if any downloads require cleanup
        infoObj := this.MultiInfoRead(multi_handle)

        ;process the messages in the infoObj
        for k,v in infoObj {
            if (v["result"] = 0) {
                this._performCleanup(v["easy_handle"])
                this.RemoveEasyFromMulti(v["easy_handle"],multi_handle)
                this._RefreshEasyHandleForAsync(v["easy_handle"])
            }
        }
        return still_running
    }
    Sync(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        multi_handle := this.easyHandleMap[easy_handle]["associated_multi_handle"]? ;Intentionally does NOT default
        If IsSet(multi_handle) {
            this.RemoveEasyFromMulti(easy_handle,multi_handle)
        }

        this._fallbackWrite(easy_handle)

        If ret := this._Perform(easy_handle?)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_perform",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)

        ; MsgBox ret
        return ret
    }
    RawSend(outgoing,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        switch Type(outgoing) {
            case "String","Integer":
                outBuffer := this._StrBuf(outgoing)
            case "Object","Array","Map":
                outBuffer := this._StrBuf(json.dump(outgoing))
            case "File":
                outBuffer := Buffer(outgoing.length)  ;create the buffer with the right size
                outgoing.RawRead(outBuffer) ;read the file into the buffer
            case "Buffer":
                outBuffer := outgoing
            Default:
                throw ValueError("Unknown object type passed to RawSend: " Type(outgoing))
        }
        sent := 0
        if ret := this._curl_easy_send(easy_handle,outBuffer,outBuffer.size,&sent)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_send",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)

        return sent
    }
    RawReceive(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        retBuffer := Buffer(0)   ;makes no assumptions on incoming size
        replyBuffer := Buffer(32 * 1024 * 1024)    ;allocates 32mb for wash loop, same as curl
        got := 0
        offset := 0
        loop {
            if ret := this._curl_easy_recv(easy_handle,replyBuffer,replyBuffer.size,&got)
                this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_recv",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)

            offsetPtr := retBuffer.ptr + got

            ;append data to buffer if any was received
            if (retBuffer.size + got > retBuffer.size)  {
                ;resize buffer to accomodate new data
                retBuffer.Size += got

                ;do the copy
                DllCall("kernel32.dll\RtlMoveMemory", "Ptr", retBuffer.ptr + offset, "Ptr", replyBuffer, "UInt", got, "Cdecl")
                
                ;update offset by the bytes copied
                offset += got
            }
        } until (got = 0)   ;break on no data received
        return retBuffer
    }
    WebSocketSend(content,flagArr := ["TEXT"],easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        
        ;push a lone flag string into a a flagArr
        if (Type(flagArr)="String")
            flagArr := [flags]

        ;parse the flags
        flags := 0
        for k,v in flagArr
            flags += this.constants["CURLWS"][v]

        switch Type(content) {
            case "String","Integer":
                buf := this._StrBuf(content,"UTF-8")
                buf.size -= 1   ;truncates a trailing binary zero
            case "Object","Array","Map":
                buf := this._StrBuf(json.dump(content),"UTF-8")
                buf.size -= 1   ;truncates a trailing binary zero
            case "File":
                filePath := this._GetFilePathFromFileObject(content)
                buf := FileRead(filePath)
            case "Buffer":
                buf := content
            Default:
                throw ValueError("Unknown object type passed as WebSocketSend content: " Type(content))
        }

        fragsize := 0
        maxframesize := this.easyHandleMap[easy_handle]["frame_size"]
        iterations := Ceil(buf.size / maxframesize)

        if iterations > 1{
            fragsize := buf.size
            flags += this.constants["CURLWS"]["OFFSET"]
        }
        
        offset := 0
        
        loop iterations {
            if ret := this._curl_ws_send(easy_handle,buf.ptr + offset,min(buf.size-offset,maxframesize),&sent := 0,fragsize,flags)
                this._ErrorHandler(A_ThisFunc,"CURLcode","curl_ws_send",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
            fragsize := 0
            offset += sent
        } until !sent
        return ret
    }
    WebSocketReceive(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        outBuf := Buffer(0)
        loop {
            ret := this._curl_ws_recv(easy_handle,outbuf,outbuf.size,&recv,&meta)
            
            switch ret {
                case 0:
                    metaMap := this.struct.curl_ws_frame(meta)
                    if metaMap["bytesleft"]
                        outBuf.Size += metaMap["bytesleft"]
                    else
                        break
                case 81:    ;waiting for ready state
                ;normal traffic so only capture with debug enabled
                If (this.easyHandleMap[easy_handle]["debug"] = 1)
                    this._ErrorHandler(A_ThisFunc,"CURLcode","curl_ws_recv",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)

                ;short sleep before checking again for ready
                Sleep(50)
                continue

                Default:    ;any other error
                    this._ErrorHandler(A_ThisFunc,"CURLcode","curl_ws_recv",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
                    return ret
            }

        }
        this.easyHandleMap[easy_handle]["lastBody"] := outBuf
        return ret
    }
    SetWebSocketFrameSize(frame_size := 10 * 1024,easy_handle?){ ;outgoing traffic will be auto-split at this size
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        this.easyHandleMap[easy_handle]["frame_size"] := frame_size
    }
    WebSocketConvert(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        ;prepare the handle options
        this.SetOpt("CONNECT_ONLY",2,easy_handle)
        this.SetWebSocketFrameSize(10 * 1024,easy_handle?)
        this.easyHandleMap[easy_handle]["websocket_mode"] := 1
        this.Sync(easy_handle)
    }

    GetLastHeaders(returnAsEncoding := "UTF-8",easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        lastHeaders := this.easyHandleMap[easy_handle]["lastHeaders"]

        if ((returnAsEncoding = "Object") && IsObject(lastHeaders))
        || ((returnAsEncoding = "File") && (Type(lastHeaders) = "File"))
        || ((returnAsEncoding = "Buffer") && (Type(lastHeaders) = "Buffer"))
            return lastHeaders

        RegexMatch(returnAsEncoding,"i)(?:Object|File|Buffer|(\S+))",&f) ;filter object types
        return (Type(lastHeaders)="File"?(lastHeaders.seek(0,0)=1?"":"") lastHeaders.read()
            :StrGet(lastHeaders,(f[1]=returnAsEncoding?f[1]:"UTF-8")))
    }
    GetLastBody(returnAsEncoding := "UTF-8",easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        lastBody := this.easyHandleMap[easy_handle]["lastBody"]

        if ((returnAsEncoding = "Object") && IsObject(lastBody))
        || ((returnAsEncoding = "File") && (Type(lastBody) = "File"))
        || ((returnAsEncoding = "Buffer") && (Type(lastBody) = "Buffer"))
            return lastBody
        
        RegexMatch(returnAsEncoding,"i)(?:Object|File|Buffer|(\S+))",&f) ;filter object types
        return (Type(lastBody)="File"?(lastBody.seek(0,0)=1?"":"") lastBody.read()
            :StrGet(lastBody,(f[1]=returnAsEncoding?f[1]:"UTF-8")))
    }
    GetLastStatus(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        return this.easyHandleMap[easy_handle]["statusCode"]
    }

    Cleanup(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        for k,v in this.easyHandleMap[easy_handle]["callbacks"]
            if IsInteger(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])
                CallbackFree(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])

        ; make sure the easy_handle is disassociated from its multi_handle, if applicable
        If this.easyHandleMap[easy_handle].has("associated_multi_handle"){
            multi_handle := this.easyHandleMap[easy_handle]["associated_multi_handle"] ;Intentionally does NOT default
            this.RemoveEasyFromMulti(easy_handle,multi_handle)
        }

        this.easyHandleMap.Delete(easy_handle)
        for k,v in this.easyHandleMap[0] {
            if (v = easy_handle){
                this.easyHandleMap[0].RemoveAt(k)
                break
            }
        }

        this._curl_easy_cleanup(easy_handle)    ;no error code return
        if (this.easyHandleMap[0].length = 0)   ;ensures there's always a usable easy_handle
            this.EasyInit()
    }
    EasyCleanup(easy_handle?){   ;alias for Cleanup
        this.Cleanup(easy_handle?)
    }
    MultiCleanup(multi_handle?){
        ;Gracefully closes a multi_handle *plus* all associated easy_handles.
        ;Any easy_handles you want to keep should be manually removed prior.
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle
        
        ;Process the associated easy_handles first
        for k,v in this.MultiGetHandles(){
            easy_handle := v
            this.RemoveEasyFromMulti(easy_handle,multi_handle)
            this.EasyCleanup(easy_handle)
        }

        return this._curl_multi_cleanup(multi_handle)
    }
    Pause(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        if ret := this._curl_easy_pause(easy_handle,PauseMode := 5)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_pause",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        return ret
    }
    UnPause(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        
        if ret := this._curl_easy_pause(easy_handle,PauseMode := 0)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_pause",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        return ret
    }
    Upkeep(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle

        if ret := this._curl_easy_upkeep(easy_handle)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_upkeep",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        return ret
    }
    ; UrlEscape(){
    ;     ;todo - write a Unicode-aware string escaper
    ; }
    ; UrlUnescape(){

    ; }

	SetHeaders(headersObject,easy_handle?) {    ;Sets custom HTTP headers for request.
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        
        headersArray := this._formatHeaders(headersObject)
        headersPtr := this._ArrayToSList(headersArray)
		Return this.SetOpt("HTTPHEADER", headersPtr,easy_handle?)
	}

    SetPost(sourceData,easy_handle?){    ;properly encapsulates data to be POSTed
        ;you can pass:
        ;   -normal text/numbers
        ;   -a File/Buffer object to upload as binary
        ;   -an Object/Array/Map to dump as JSON

        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        this.easyHandleMap[easy_handle]["postData"] := unset    ;clears last POST. prolly redundant but eh.
        this.easyHandleMap[easy_handle]["postFile"] := unset    ;clears last POST. prolly redundant but eh.

        switch Type(sourceData) {
            case "String","Integer":
                this.easyHandleMap[easy_handle]["postData"] := this._StrBuf(sourceData)
            case "Object","Array","Map":
                this.easyHandleMap[easy_handle]["postData"] := this._StrBuf(json.dump(sourceData))
            case "File":
                this._setCallbacks(,,1,,easy_handle)
                
                ;generate an independent file handle
                sourceData := FileOpen(this._GetFilePathFromFileObject(sourceData),"r")
                sourceData.Seek(0) ;ensures we're before any BOM (ahk quirk)
                this.easyHandleMap[easy_handle]["postFile"] := sourceData

                ;mandatory steps if the last POST was non-File
                this.SetOpt("POSTFIELDS",0,easy_handle)
                this.SetOpt("POSTFIELDSIZE_LARGE",sourceData.length, easy_handle)

                ;File-specific upload settings
                this.SetOpt("INFILESIZE_LARGE",sourceData.length, easy_handle)
                this.SetOpt("POST", 1, easy_handle)
            case "Buffer":
                this.easyHandleMap[easy_handle]["postData"] := sourceData
                this.SetOpt("POSTFIELDSIZE_LARGE",sourceData.size, easy_handle)
            Default:
                throw ValueError("Unknown object type passed as POST data: " Type(sourceData))
        }

        if (Type(sourceData) != "File")
            this.SetOpt("POSTFIELDS",this.easyHandleMap[easy_handle]["postData"])
    }
    ClearPost(easy_handle?){    ;clears any lingering POST data
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        this.SetOpt("HTTPPOST",0,easy_handle)
        this.SetOpt("MIMEPOST",0,easy_handle)
        this.SetOpt("HTTPGET",1,easy_handle)

        this.SetOpt("POSTFIELDS",0,easy_handle)
        this.SetOpt("POSTFIELDSIZE",0,easy_handle)
        this.SetOpt("POSTFIELDSIZE_LARGE",0,easy_handle)
        this.SetOpt("INFILESIZE",-1,easy_handle)    ;-1 = disabled
        this.SetOpt("INFILESIZE_LARGE",-1,easy_handle)  ;-1 = disabled

        this.easyHandleMap[easy_handle]["postFile"] := unset
        this.easyHandleMap[easy_handle]["postData"] := unset
    }

    UrlInit(){
        url_handle := this._curl_url()
        this.urlHandleMap[0].push(url_handle) ;urlHandleMap[0][1] is a dynamic reference to the first created url_handle
        this.urlHandleMap[url_handle] := Map() 
        this.urlHandleMap[url_handle]["url_handle"] := url_handle
        this.urlHandleMap[url_handle]["timestamp"] := A_NowUTC
        return url_handle
    }
    UrlCleanup(url_handle?){
        url_handle ??= (this.urlHandleMap[0][1])   ;defaults to the first created url_handle
        this._curl_url_cleanup(url_handle)
        this.urlHandleMap.Delete(url_handle)
        for k,v in this.urlHandleMap[0] {
            if (v = url_handle){
                this.urlHandleMap[0].RemoveAt(k)
                break
            }
        }
        if (this.urlHandleMap[0].length = 0)    ;ensures there's always a handle available
            this.UrlInit()
    }
    DupeUrl(url_handle?){
        url_handle ??= this.urlHandleMap[0][1]   ;defaults to the first created url_handle
        newUrl := this._curl_url_dup(url_handle)
        this.urlHandleMap[0].push(newUrl)
        this.urlHandleMap[newUrl] := this._DeepClone(this.urlHandleMap[url_handle])
        this.urlHandleMap[newUrl]["timestamp"] := A_NowUTC
    }

    UrlSet(part,content,flags := [],url_handle?){
        url_handle ??= this.urlHandleMap[0][1]   ;defaults to the first created url_handle

        flagBitmask := 0
        for k,v in flags
            flagBitmask += this.constants["CURLUflags"][v]

        partConstant := this.constants["CURLUPart"][part]
        return this._curl_url_set(url_handle,partConstant,content,flagBitmask)
    }
    UrlGet(part,flags := [], url_handle?){
        url_handle ??= this.urlHandleMap[0][1]   ;defaults to the first created url_handle

        flagBitmask := 0
        for k,v in flags
            flagBitmask += this.constants["CURLUflags"][v]

        partConstant := this.constants["CURLUPart"][part]
        retCode := this._curl_url_get(url_handle,partConstant,&content := 0,flagBitmask)
        ret := StrGet(content,"UTF-8")
        this._curl_free(content)
        return ret
    }

    MultiInfoRead(multi_handle?){
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle
        retObj := []
        while (retCode := this._curl_multi_info_read(multi_handle,&msgsInQueue)) {
            retObj.push(this.struct.curl_CURLMsg(retCode))
        }
        
        return retObj
        ; msgbox this.PrintObj(retObj)
        ; msgbox retCode "`n" msgsInQueue
    }

    MultiInit(){    ;auto-invoked during register()
        multi_handle := this._curl_multi_init()
        this.multiHandleMap[0].push(multi_handle) ;multiHandleMap[0][1] is a dynamic reference to the last created multi_handle
        this.multiHandleMap[multi_handle] := Map()
        this.multiHandleMap[multi_handle]["options"] := Map()
        this.multiHandleMap[multi_handle]["associatedEasyHandles"] := Map()
        return multi_handle
    }
    AddEasyToMulti(easy_handle?,multi_handle?){ ;auto-invoked during EasyInit()
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle

        ret := this._curl_multi_add_handle(multi_handle,easy_handle)
        this.easyHandleMap[easy_handle]["associated_multi_handle"] := multi_handle
        this.multiHandleMap[multi_handle]["associatedEasyHandles"][easy_handle] := A_NowUTC
        ; this.multiHandleMap["pending_callbacks"].push(easy_handle)
        return ret
    }
    _fallbackWrite(easy_handle){
        static checkTypes := ["WRITE","HEADER"]
        for k,v in checkTypes
        If !this.easyHandleMap[easy_handle]["options"].Has(v "DATA")
            this.%v%ToMem(,easy_handle)
    }
    RemoveEasyFromMulti(easy_handle?,multi_handle?) {
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle
        If ret := this._curl_multi_remove_handle(multi_handle,easy_handle)
            this._ErrorHandler(A_ThisFunc,"CURLMcode","curl_multi_remove_handle",ret,this.multiHandleMap[multi_handle]["error buffer"],multi_handle)
        this.easyHandleMap[easy_handle]["associated_multi_handle"] := unset
        this.multiHandleMap[multi_handle]["associatedEasyHandles"][easy_handle] := unset
        return ret
    }
    SwapMultiPools(easyHandleArr,oldMultiHandle,newMultiHandle){   ;used to transfer easy_handles between multi_handles
        for k,v in easyHandleArr{   ;array of easy_handles
            this.RemoveEasyFromMulti(v,oldMultiHandle)
            this.AddEasyToMulti(v,newMultiHandle)
        }
    }
    GetInfo(infoOption,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        if ret := this._curl_easy_getinfo(easy_handle,infoOption,&info := 0)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_getinfo",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)

        switch this.constants["CURLINFO"][infoOption]["infoType"] {
            case "STRING":
                return StrGet(info,"UTF-8")
            case "PTR":
                return (info!=0?numget(info,"ptr"):0)
            default:
                return info
        }
    }
    GetAllHeaders(easy_handle?) {   ;use GetLastHeaders() unless you need to examine the headers from a redirect
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        static c := this.constants["CURLH_ORIGINS"]
        
        redirects := this.GetInfo("REDIRECT_COUNT")
        retObj := []

        ;todo - check out the other origin types
        origin ??= c["HEADER"]
        
        loop redirects + 1 {
            request := a_index - 1
            previous_curl_header := 0
            retObj.Push([])
            specificRetObj := retObj[retObj.Length]

            loop{
                headerPtr := this._curl_easy_nextheader(easy_handle,origin,request,previous_curl_header)
                If !headerPtr
                    break
                specificRetObj.Push(this.struct.curl_header(headerPtr))    
                previous_curl_header := headerPtr
            }
        }
        return retObj
    }
    InspectHeader(name,index := 0, origin?,request := -1,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        static c := this.constants["CURLH_ORIGINS"]
        origin ??= c["HEADER"]

        ;todo - add CURLHcode handling
        ret := this._curl_easy_header(easy_handle,name,index,origin,request,&curl_header := 0)
        If curl_header
            return this.struct.curl_header(curl_header)["value"]
        return unset
    }
    PrintObj(ObjectMapOrArray,depth := 5,indentLevel := ""){
        ; static self := StrSplit(A_ThisFunc,".")[StrSplit(A_ThisFunc,".").Length]
        list := ""
        For k,v in (Type(ObjectMapOrArray)!="Object"?ObjectMapOrArray:ObjectMapOrArray.OwnProps()){
            list .= indentLevel "[" k "]"
            Switch Type(v) {
                case "Map","Array","Object":
                    list .= "`n" this.PrintObj(v,depth-1,indentLevel  "    ")
                case "Buffer","LibQurl.Storage.MemBuffer":
                    list .= " => [BUFFER] "
                case "File","LibQurl.Storage.File":
                    list .= " => [FILE] "
                case "LibQurl.Storage.Magic":
                    list .= " => [MAGIC] "
                Default:
                    list .= " => " v
            }
            list := RTrim(list,"`r`n`r ") "`n"
        }
        return RTrim(list)
    }
    ;dummied code that doesn't work right yet
    

    DupeInit(old_easy_handle?){
        ;NOTE: curl_easy_duphandle was not playing well with this class.
        ;I was unable to figure out why. It was probably something stupid. 
        ;Regardless, Init() is called instead.
        ;The end result is the same as long as you haven't bypassed SetOpt/etc.
        old_easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        new_easy_handle := this.Init()

        ;filter file/header writing callback functions as those got setup in Init
        for k,v in this.easyHandleMap[old_easy_handle]["options"] {
            switch k {
                case "WRITEDATA","WRITEFUNCTION":
                    continue
                case "HEADERDATA", "HEADERFUNCTION":
                    continue
                default:
                    this.SetOpt(k,v,new_easy_handle)
            }
        }
        ; MsgBox this.PrintObj(this.easyHandleMap[new_easy_handle]["options"])
        this.WriteToMem(0,new_easy_handle)    ;automatically save lastBody to memory
        return new_easy_handle
    }

    MultiGetHandles(multi_handle?){
        ;Returns array of all easy_handles in the multi_handle.
        ;This matches the multiHandleMap unless you've bypassed class methods.
        multi_handle ??= this.multiHandleMap[0][1] ;defaults to the first created multi_handle

        ;gets the pointer array
        ret := this._curl_multi_get_handles(multi_handle)
        

        ;walk the pointer array
        out := []
        loop 11 {
            ptr := NumGet(ret,(a_index - 1) * A_PtrSize,"Ptr")
            if (ptr = 0)    ;no more
                break
            out.Push(ptr)
        }
        return out
    }

    GetDate(dateString,returnEpoch?){
        ret := this._curl_getdate(dateString)

        if returnEpoch ??= 0
            return ret
        return DateAdd(1970, ret, 'S')
    }

    ShareInit(){
        share_handle := this._curl_share_init()
        this.shareHandleMap[0].push(share_handle) ;shareHandleMap[0][1] is a dynamic reference to the first created share_handle
        this.shareHandleMap[share_handle] := Map()
        this.shareHandleMap[share_handle]["options"] := Map()
        this.shareHandleMap[share_handle]["associatedEasyHandles"] := Map()
        this.shareHandleMap[share_handle]["error buffer"] := Buffer(this.CURL_ERROR_SIZE)
        return share_handle
    }
    AddEasyToShare(easy_handle?,share_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        share_handle ??= this.shareHandleMap[0][1] ;defaults to the first created share_handle

        if ret := this.SetOpt("SHARE",share_handle,easy_handle)
            this._ErrorHierarchy(A_ThisFunc,"CURLSHcode",share_handle)
            ,this._ErrorHierarchy(A_ThisFunc,"CURLcode",easy_handle)
        this.easyHandleMap[easy_handle]["associated_share_handle"] := share_handle
        this.shareHandleMap[share_handle]["associatedEasyHandles"][easy_handle] := A_NowUTC
        return ret
    }
    RemoveEasyFromShare(easy_handle?,share_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        share_handle ??= this.shareHandleMap[0][1] ;defaults to the first created share_handle

        if ret := this.SetOpt("SHARE",0,easy_handle)
            this._ErrorHierarchy(A_ThisFunc,"CURLSHcode",share_handle)

        this.easyHandleMap[easy_handle]["associated_share_handle"] := unset
        this.shareHandleMap[share_handle]["associatedEasyHandles"][easy_handle] := unset
        return ret
    }
    ShareCleanup(share_handle?){
        share_handle := this.shareHandleMap[0][1]   ;defaults to the first created share_handle
        if ret := this._curl_share_cleanup(share_handle)
            this._ErrorHandler(A_ThisFunc,"CURLSHcode","curl_share_cleanup",ret,,share_handle)
        return ret
    }

    ShareSetOpt(option,parameter,share_handle?){
        share_handle := this.shareHandleMap[0][1]   ;defaults to the first created share_handle

        If this.sOpt.Has(option){
            ;nothing to be done
        } else if InStr(option,"CURLSHOPT_") && this.sOpt.Has(StrReplace("CURLSHOPT_",option)){
            option := StrReplace("CURLSHOPT_",option)
        } else {
            throw ValueError("Problem in 'curl_share_setopt'! Unknown option: " option, -1, this.curlDLLpath)
        }
        
        parameter := this.constants["curl_lock"][parameter]
        this.shareHandleMap[share_handle]["options"][option] := parameter

        if ret := this._curl_share_setopt(share_handle,option,parameter)
            this._ErrorHandler(A_ThisFunc,"CURLSHcode","curl_share_setopt",ret,this.shareHandleMap[share_handle]["error buffer"],share_handle)
        return ret
    }
    ShareGetOpt(option,share_handle?){
        share_handle := this.shareHandleMap[0][1]   ;defaults to the first created share_handle

        if this.shareHandleMap[share_handle]["options"].has(option)
            return this.shareHandleMap[share_handle]["options"][option]
        Return Null()
    }


    MimeInit(easy_handle?) {    ;curl requires associating mime_handles to an easy_handle
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        mime_handle := this._curl_mime_init(easy_handle)

        this.mimeHandleMap[0].push(mime_handle)
        this.mimeHandleMap[mime_handle] := Map()
        this.mimeHandleMap[mime_handle]["associated_easy_handle"] := easy_handle
        this.mimeHandleMap[mime_handle]["associated_mime_parts"] := Map()

        this.easyHandleMap[easy_handle]["active_mime_handle"] := mime_handle
        this.easyHandleMap[easy_handle]["associated_mime_handles"][mime_handle] := 1
        this.mimeHandleMap[mime_handle]["nested"] := 0
        this.SetOpt("MIMEPOST",mime_handle,easy_handle)

        return mime_handle
    }
    MimeAddPart(mime_handle?){
        mime_handle ??= this.mimeHandleMap[0][1]   ;defaults to the first created mime_handle

        mime_part := this._curl_mime_addpart(mime_handle)
        this.mimePartMap[mime_part] := partMap := Map()
        
        partMap["associated_mime_handle"] := mime_handle
        partMap["associated_easy_handle"] :=  this.mimeHandleMap[mime_handle]["associated_easy_handle"]

        this.mimeHandleMap[mime_handle]["associated_mime_parts"][mime_part] := 1

        return mime_part
    }
    MimePartName(mime_part,partName){
        this._curl_mime_name(mime_part,partName)
        this.mimePartMap[mime_part]["name"] := partName
    }
    MimePartData(mime_part,partContent){
        ;File doesn't use this callback but still checks for the Map during cleanup
        partMap := this.mimePartMap[mime_part]
        partMap["callbacks"] := CBFmap := Map()

        ;get the data into the correct format
        switch Type(partContent) {
            case "String","Integer":
                buf := this._StrBuf(partContent,"UTF-8")
                buf.size -= 1   ;truncates a trailing binary zero
                ; this._curl_mime_data(mime_part,buf,-1)
            case "Object","Array","Map":
                buf := this._StrBuf(json.dump(partContent),"UTF-8")
                buf.size -= 1   ;truncates a trailing binary zero
                ; this._curl_mime_data(mime_part,buf,buf.size-1)
            case "File":
                filePath := this._GetFilePathFromFileObject(partContent)
                If ret := this._curl_mime_filedata(mime_part,filePath){
                    easy_handle := partMap["associated_easy_handle"]
                    this._ErrorHandler(A_ThisFunc,"CURLcode","curl_mime_data_cb",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
                }
                return ret  ;early return because there's no need to store anything
            case "Buffer":
                buf := partContent
                ; this._curl_mime_data(mime_part,buf,partContent.size)
            Default:
                throw ValueError("Unknown object type passed as mime_part content: " Type(partContent))
        }

        ;store the data in the correct location
        partMap["content"] ??= buf

        ;create the callbacks
        partMap["offset"] := 0
        rCBF := CBFmap["read"] := CallbackCreate(
            (buf, size, nitems, mime_part) =>
            this._mimeDataReadCallbackFunction(buf, size, nitems, mime_part)
        )
        sCBF := CBFmap["seek"] := CallbackCreate(
            (mime_part, offset, origin) =>
            this._mimeDataSeekCallbackFunction(mime_part, offset, origin)
        )
        fCBF := CBFmap["free"] := CallbackCreate(
            (mime_part) =>
            this._mimeDataFreeCallbackFunction(mime_part)
        )

        ;hand off everything to libcurl
        If ret := this._curl_mime_data_cb(mime_part,buf.size,rCBF,sCBF,fCBF,mime_part){
            easy_handle := partMap["associated_easy_handle"]
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_mime_data_cb",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        }

        return ret
    }
    MimePartType(mime_part,partContent?,override?){
        If IsSet(override?)
            return this._curl_mime_type(mime_part,override)

        switch Type(partContent) {
            case "String","Integer":
                mime_type := this.magic.mime(mime_part)
                this._curl_mime_type(mime_part,mime_type)
            case "Object","Array","Map":
                mime_type := this.magic.mime(json.dump(partContent))
                this._curl_mime_type(mime_part,mime_type)
            case "File":
                mime_type := this.magic.mime(partContent)
                this._curl_mime_type(mime_part,mime_type)
            case "Buffer":
                mime_type := this.magic.mime(mime_part)
                this._curl_mime_type(mime_part,mime_type)
            Default:
                throw ValueError("Unknown object type passed as mime_part content: " Type(partContent))
        }

        this.mimePartMap[mime_part]["type"] := mime_type
    }
    AttachMimePart(partName,partContent,mime_handle?){
        mime_handle ??= this.mimeHandleMap[0][1]   ;defaults to the first created mime_handle
        
        mime_part := this.MimeAddPart(mime_handle)

        this.MimePartName(mime_part,partName)
        this.MimePartData(mime_part,partContent)
        this.MimePartType(mime_part,partContent)

        return mime_part
    }
    MimeCleanup(mime_handle?){
        mime_handle ??= this.mimeHandleMap[0][1]   ;defaults to the first created mime_handle

        ;prevent cleaning up nested mime_handles
        if this.mimeHandleMap[mime_handle]["nested"]
            return

        ;break easy_handle association
        easy_handle := this.mimeHandleMap[mime_handle]["associated_easy_handle"]
        if (this.easyHandleMap[easy_handle]["active_mime_handle"] = mime_handle){
            this.easyHandleMap[easy_handle]["active_mime_handle"] := 0  ;don't want to auto-revert for the user
        }
        this.easyHandleMap[easy_handle]["associated_mime_handles"][mime_handle] := unset
        

        ;cull tracked mime_part info
        for k,v in this.mimeHandleMap[mime_handle]["associated_mime_parts"] {
            ; this.mimePartMap.Delete(k)
            this._mimePartCleanup(k)
        }
        
        ;stop tracking the mime_handle
        this.mimeHandleMap.Delete(mime_handle)
        for k,v in this.mimeHandleMap[0] {
            if (v = mime_handle){
                this.mimeHandleMap[0].RemoveAt(k)
                break
            }
        }

        ;delete the mime_handle
        this._curl_mime_free(mime_handle)

        ;free the staged callbacks
        loop this.mimePartCBFcleanupArr.Length
            CallbackFree(this.mimePartCBFcleanupArr.Pop())
    }
    MimePartEncoder(mime_part,encoding := ""){
        ;I honestly have no idea how to use this.
        ret := this._curl_mime_encoder(mime_part,encoding)
        return ret
    }
    MimeTreatPartAsFile(mime_part,filename := ""){
        ;Used to have the remote server treat a mime_part as a file
        ;Not required when Attaching FileObjects as curl does it internally.
        ;Pass an empty filename string to disable this mode for this mime_part, even for real files.
        ret := this._curl_mime_filename(mime_part,filename)
        return ret
    }

    AttachMimeAsPart(partName,mime_to_embed,mime_handle?){
        ;this attaches an entire other mime_handle to the given mime_part
        mime_handle ??= this.mimeHandleMap[0][1]   ;defaults to the first created mime_handle
        
        ;prevent attempting to nest the mime_handle within itself
        if (mime_to_embed = mime_handle)
            return

        mime_part := this.AttachMimePart(partName,"",mime_handle)
        ret := this._curl_mime_subparts(mime_part,mime_to_embed)

        ;tag the tracked mime_handle as nested
        this.mimeHandleMap[mime_to_embed]["nested"] := mime_handle
        this.mimePartMap[mime_part]["associated_mime_parts"] := this.mimeHandleMap[mime_to_embed]["associated_mime_parts"]

        return mime_part
    }
	SetMimePartHeaders(mime_part,headersObject) {    ;Sets custom HTTP headers for request.
        headersArray := this._formatHeaders(headersObject)
        headersPtr := this._ArrayToSList(headersArray)
		Return this._curl_mime_headers(mime_part,headersPtr,1)
	}
    GetMimeType(sourceData){ ;Analyzes the input's mimetype without any other operations
        switch Type(sourceData) {
            case "String","Integer":
                return this.magic.mime(sourceData)
            case "Object","Array","Map":
                return this.magic.mime(json.dump(sourceData))
            case "File":
                return this.magic.mime(sourceData)
            case "Buffer":
                return this.magic.mime(sourceData)
            Default:
                throw ValueError("Unknown object type passed as mime_part content: " Type(sourceData))
        }
    }
    StrCompare(str1,str2,maxLength?){
        ;returns 1 on match
        If IsSet(maxLength?)
            return this._curl_strnequal(str1,str2,maxLength?)
        return this._curl_strequal(str1,str2)
    }
    GetEnv(input){  ;gets the specified system variable
        retPtr := this._curl_getenv(input)
        if !retPtr
            return
        retStr := StrGet(retPtr,"UTF-8")
        this._curl_free(retPtr)
        return retStr
    }
    EncodeBase64(input){
        ;prepare the buffer to convert to base64
        switch Type(input) {
            case "String","Integer":
                sourceBuf := this._StrBuf(input,"UTF-8")
                sourceBuf.size := StrLen(input)
            case "Object","Array","Map":
                inputJson := json.dump(input)
                sourceBuf := this._StrBuf(inputJson,"UTF-8")
                sourceBuf.size := StrLen(inputJson)
            case "File":
                sourceBuf := Buffer(input.length)  ;create the buffer with the right size
                input.Seek(0)   ;reset to the start of the file
                input.RawRead(sourceBuf) ;read the file into the buffer
            case "Buffer":
                sourceBuf := input
            Default:
                throw ValueError("Unknown object type passed to EncodeBase64: " Type(input))
        }

        ;calculate required output buffer size
        DllCall("crypt32\CryptBinaryToString"
            ,   "Ptr", sourceBuf
            ,   "UInt", sourceBuf.size
            ,   "UInt", 0x40000001  ; = base64 without headers + no CRLF
            ,   "Ptr", 0
            ,   "Uint*", &nSize := 0)
        VarSetStrCapacity(&retStr := 0, nSize << 1)

        ;generate the string
        DllCall("crypt32\CryptBinaryToString"
            ,   "Ptr", sourceBuf
            ,   "UInt", sourceBuf.size
            ,   "UInt", 0x40000001  ; = base64 without headers + no CRLF
            ,   "Str", retStr
            ,   "Uint*", &nSize)

        return retStr
    }
    DecodeBase64(str,returnBuffer?){
        ;calculate required output buffer size
		DllCall("crypt32\CryptStringToBinary"
            ,   "Str", str
            ,   "UInt", 0
            ,   "UInt", 0x00000001
            ,   "Ptr", 0
            ,   "Uint*", &SizeOut := 0
            ,   "Ptr", 0
            ,   "Ptr", 0)

        ;generate the buffer
		DllCall("Crypt32\CryptStringToBinary"
            ,   "Str", str
            ,   "UInt", 0
            ,   "UInt", 0x00000001
            ,   "Ptr", VarOut := Buffer(SizeOut)
            ,   "Uint*", &SizeOut
            ,   "Ptr", 0
            ,   "Ptr", 0)

        if IsSet(returnBuffer)
            return VarOut

		return StrGet(VarOut,"UTF-8")
    }

    GetProgress(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        retObj := this._DeepClone(this.easyHandleMap[easy_handle]["callbacks"]["progress"])
        retObj.delete("CBF")
        return retObj
    }
    DownloadPercent(easy_handle?){  ;convenience method for parsing GetProgress
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        ret := this.GetProgress(easy_handle)
        if (ret["expectedBytesDownloaded"] = 0)
            return 0
        return Round((ret["currentBytesDownloaded"] / ret["expectedBytesDownloaded"]) * 100,2)
    }
    UploadPercent(easy_handle?){    ;convenience method for parsing GetProgress
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        ret := this.GetProgress(easy_handle)
        if (ret["expectedBytesUploaded"] = 0)
            return 0
        return Round((ret["currentBytesUploaded"] / ret["expectedBytesUploaded"]) * 100,2)
    }
    EnableDebug(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        this._setCallbacks(,,,,1,easy_handle)
        this.easyHandleMap[easy_handle]["callbacks"]["debug"]["log"] := []
        this.easyHandleMap[easy_handle]["debug"] := 1
    }
    ConfigureDebug(config := ["-all"]){
        ;You can use no prefix ("all"), plus ("+all"), or minus ("-all") to control the debug level for any component.
        ;"-all" is equivalent to not calling this in the first place.
        switch Type(config){
            case "Array":
                configLevel := adash.join(config,",")
            case "String":
                configLevel := config
        }
        this._curl_global_trace(configLevel)
    }
    PollDebug(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        static infotypes := Map(
            0,"text",
            1,"header_in",
            2,"header_out",
            3,"data_in",
            4,"data_out",
            5,"ssl_data_in",
            6,"ssl_data_out"
        )
        logArr := this.easyHandleMap[easy_handle]["callbacks"]["debug"]["log"]
        out := ""
        PadLen := StrLen(logArr.length)
        For k,v in logArr {
            if v["infotype"] < 3{
                index := Format("{:0" PadLen "}",a_index)
                info := Format("{:-13}", infotypes[v["infotype"]])
                out .= index ")  " v["timestamp"] "  [" info "]:  " v["data"]
            }
        }
        return out
    }
    Timestamp(){
        ; https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimepreciseasfiletime
        static GetSystemTimePreciseAsFileTime := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "kernel32", "Ptr")
            , "AStr", "GetSystemTimePreciseAsFileTime", "Ptr")
        
        ft := Buffer(8, 0)
        DllCall(GetSystemTimePreciseAsFileTime, "Ptr", ft, "Cdecl")

        ; Convert FILETIME (100ns intervals since 1601-01-01) to SYSTEMTIME (UTC)
        ; SystemTimeFromFileTime is available via Kernel32
        static FileTimeToSystemTime := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "kernel32", "Ptr")
            , "AStr", "FileTimeToSystemTime", "Ptr")
        
        st := Buffer(16)  ; SYSTEMTIME is 16 WORDs = 16 * 2 = 32 bytes
        DllCall(FileTimeToSystemTime, "Ptr", ft, "Ptr", st)

        ; Extract and format SYSTEMTIME fields
        year   := NumGet(st,  0, "UShort")
        month  := NumGet(st,  2, "UShort")
        day    := NumGet(st,  6, "UShort")
        hour   := NumGet(st,  8, "UShort")
        minute := NumGet(st, 10, "UShort")
        second := NumGet(st, 12, "UShort")
        ms     := NumGet(st, 14, "UShort")
    
        return Format("{:04}-{:02}-{:02} {:02}:{:02}:{:02}.{:03}", year, month, day, hour, minute, second, ms)
    }
    ExportSSLs(easy_handle?,share_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        share_handle ??= this.shareHandleMap[0][1] ;defaults to the first created share_handle
        
        retArr := []
        retArrPtr := ObjPtr(retArr)

        ;create the callback to the export function
        CBF := CallbackCreate(
            (easy_handle, retArr, session_key, shmac , shmac_len, sdata, sdata_le, valid_until, ietf_tls_id, alpn, earlydata_max) =>
            this._SSLExportCallbackFunction(easy_handle, retArrPtr, session_key, shmac , shmac_len, sdata, sdata_le, valid_until, ietf_tls_id, alpn, earlydata_max)
        )

        ;proc the export
        If ret := this._curl_easy_ssls_export(easy_handle,CBF,share_handle)
            this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_ssls_export",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        
        ;callback doesn't need to be stored as this is a one-shot operation
        CallbackFree(CBF)
        
        return retArr
    }
    ImportSSLs(importArr,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][1] ;defaults to the first created easy_handle
        for k,v in importArr{
            importMap := v
            if importMap.has("session_key")
                session_key := importMap["session_key"]
            shmac := this.DecodeBase64(importMap["shmac"],1)
            sdata := this.DecodeBase64(importMap["sdata"],1)
            if ret := this._curl_easy_ssls_import(easy_handle,session_key ??= 0,shmac,sdata)
                this._ErrorHandler(A_ThisFunc,"CURLcode","curl_easy_ssls_import",ret,this.easyHandleMap[easy_handle]["error buffer"],easy_handle)
        }
    }
    ; */

    ; WriteToNone() {
    ; 	Return (this._writeTo := "")
    ; }



    ; HeaderToNone() {
    ; 	Return (this._headerTo := "")
    ; }

;#compile:helper
;#compile:_struct
;#compile:storage
;#compile:_declareConstants
;#compile:dll
}