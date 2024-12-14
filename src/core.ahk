;This file contains the core features of LibQurl.
;Generally, anything a user might want to directly access should go here.
;leave the #compile:whatever lines at the bottom!
;when adding dependencies, use the "*i <lib>" format. It will be cleaned up by the generator.
;***
#requires Autohotkey v2.1-alpha.9
#Include "*i <Aris\G33kDude\cJson>"
class LibQurl {
    ;core functionality
    __New(dllPath?,requestedSSLprovider?) {
        this.easyHandleMap := Map()
        this.easyHandleMap[0] := []
        this.urlHandleMap := Map()
        this.urlHandleMap[0] := []
        this.multiHandleMap := Map()
        this.multiHandleMap[0] := []
        this.multiHandleMap["pending_callbacks"] := []
        this.multiHandleMap["running_callbacks"] := []
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
        this.CURL_ERROR_SIZE := 256
        this._register(dllPath?,requestedSSLprovider?)
    }
    _register(dllPath?,requestedSSLprovider?) {
        Critical "On"   ;so the DLL loading doesn't get interrupted

        ;todo - make dll auto-load feature more robust
        ;determine where the dll will load from
        if !FileExist(dllPath)
            dllPath := this._findDLLfromAris()  ;will try to fallback on the installed package directory
        if !FileExist(dllPath)
            throw ValueError("libcurl DLL not found!", -1, dllPath)

        ;save the current working dir so we can safely load the DLL
        oldWorkingDir := A_WorkingDir
        SplitPath(dllPath,,&dllDir)
        SetWorkingDir(dllDir)

        ;load the DLL into resident memory
        this.curlDLLpath := dllpath
        this.curlDLLhandle := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

        ;restore the user's intended workingDir
        A_WorkingDir := oldWorkingDir
        
        ;out of the danger zone
        Critical "Off"

        ;continue loading
        this._configureSSL(requestedSSLprovider?)   
        this._curl_global_init()
        OnExit (*) => this._globalCleanup()
        this._declareConstants()
        this._declareConstants()
        this._buildOptMap()
        this.VersionInfo := this.GetVersionInfo()
        this.UrlInit()
        this.MultiInit()
        this.Init()
        return
    }
    Init(){
        easy_handle := this._curl_easy_init()
        this.easyHandleMap[0].push(easy_handle) ;easyHandleMap[0][-1] is a dynamic reference to the last created easy_handle
        this.easyHandleMap[easy_handle] := Map() 

        If !this.easyHandleMap[easy_handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)

        this.easyHandleMap[easy_handle]["easy_handle"] := easy_handle
        this.easyHandleMap[easy_handle]["options"] := Map()  ;prepares option storage
        this.SetOpt("ACCEPT_ENCODING","",easy_handle)    ;enables compressed transfers without affecting input headers
        ; this.SetOpt("SSH_COMPRESSION",1,easy_handle)    ;enables compressed transfers without affecting input headers
        this.SetOpt("FOLLOWLOCATION",1,easy_handle)    ;allows curl to follow redirects
        this.SetOpt("MAXREDIRS",30,easy_handle)    ;limits redirects to 30 (matches recent curl default)

        ;try to auto-load curl's cert bundle
        ;can still be set per easy_handle
        SplitPath(this.curlDLLpath,,&dlldir)
        If FileExist(dlldir "\curl-ca-bundle.crt")
            this.SetOpt("CAINFO",dlldir "\curl-ca-bundle.crt",easy_handle)

        ;todo - autoupdate the cert bundle
        this.easyHandleMap[easy_handle]["callbacks"] := Map()  ;prepares write callbacks
        for k,v in ["body","header","read","progress","debug"]{
            this.easyHandleMap[easy_handle]["callbacks"][v] := Map()
            this.easyHandleMap[easy_handle]["callbacks"][v]["CBF"] := ""
        }


        this._setCallbacks(1,1,1,1,,easy_handle) ;don't enable debug by default
        this.HeaderToMem(0,easy_handle)    ;automatically save lastHeader to memory
        return easy_handle
    }
    EasyInit(multi_handle?){ ;just a clarifying alias for Init()
        return this.Init(multi_handle?)
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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle

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
        return this._curl_easy_setopt(easy_handle,option,parameter,debug?)
    }
    MultiSetOpt(option,parameter,multi_handle?){
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle

        If this.mOpt.Has(option){
            ;nothing to be done
        } else if InStr(option,"CURLMOPT_") && this.mOpt.Has(StrReplace("CURLMOPT_",option)){
            option := StrReplace("CURLMOPT_",option)
        } else {
            throw ValueError("Problem in 'curl_multi_setopt'! Unknown option: " option, -1, this.curlDLLpath)
        }

        this.multiHandleMap[multi_handle]["options"][option] := parameter
        return this.curl_multi_setopt(multi_handle,option,parameter)
    }
    SetOpts(optionMap,&optErrMap?,easy_handle?){  ;for setting multiple options at once
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
	HeaderToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
		this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity := 65536, dataSize?, &passedHandleMap, "header", easy_handle)
        
        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
        Return
	}


    WriteToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "body", easy_handle)
        ; this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].Ptr := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"]
        ; writeTo := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"]:= LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "body", easy_handle)
        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle)
		Return
	}

	HeaderToFile(filename, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "header", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
		Return
	}

    WriteToFile(filename, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "body", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle) 
        Return
    }
    ReadyAsync(inEasyHandles,multi_handle?){    ;Add any number of easy_handles to the multi pool. Accepts integers or object.
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle
        If (Type(inEasyHandles) = "Integer")
            inEasyHandles := [inEasyHandles]
        for k,v in (Type(inEasyHandles)!="Object"?inEasyHandles:inEasyHandles.OwnProps()) { ;itemize Objects if required
            this.AddEasyToMulti(v,multi_handle)
        }
        
    }
    Async(multi_handle?){
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle

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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        multi_handle := this.easyHandleMap[easy_handle]["associated_multi_handle"]? ;Intentionally does NOT default
        If IsSet(multi_handle) {
            this.RemoveEasyFromMulti(easy_handle,multi_handle)
        }
        return this._Perform(easy_handle?)    
    }
    RawSend(outgoing,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle

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
        this._curl_easy_send(easy_handle,outBuffer,outBuffer.size,&sent)
        return sent
    }
    RawReceive(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        retBuffer := Buffer(0)   ;makes no assumptions on incoming size
        replyBuffer := Buffer(32 * 1024 * 1024)    ;allocates 32mb for wash loop, same as curl
        got := 0
        offset := 0
        loop {
            ret := curl._curl_easy_recv(easy_handle,replyBuffer,replyBuffer.size,&got)
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

    GetLastHeaders(returnAsEncoding := "UTF-8",easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        lastBody := this.easyHandleMap[easy_handle]["lastBody"]
        if ((returnAsEncoding = "Object") && IsObject(lastBody))
        || ((returnAsEncoding = "File") && (Type(lastBody) = "File"))
        || ((returnAsEncoding = "Buffer") && (Type(lastBody) = "Buffer"))
            return lastBody
        RegexMatch(returnAsEncoding,"i)(?:Object|File|Buffer|(\S+))",&f) ;filter object types
        return (Type(lastBody)="File"?(lastBody.seek(0,0)=1?"":"") lastBody.read()
            :StrGet(lastBody,(f[1]=returnAsEncoding?f[1]:"UTF-8")))
    }

    Cleanup(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        for k,v in this.easyHandleMap[easy_handle]["callbacks"]
            if IsInteger(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])
                CallbackFree(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])
        this.easyHandleMap.Delete(easy_handle)
        for k,v in this.easyHandleMap[0] {
            if (v = easy_handle){
                this.easyHandleMap[0].RemoveAt(k)
                break
            }
        }
        this._curl_easy_cleanup(easy_handle)
        if (this.easyHandleMap[0].length = 0)   ;ensures there's always a usable easy_handle
            this.EasyInit()
    }
    EasyCleanup(easy_handle?){   ;alias for Cleanup
        this.Cleanup(easy_handle?)
    }

    Pause(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        return this._curl_easy_pause(easy_handle,PauseMode := 5)
    }
    UnPause(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        return this._curl_easy_pause(easy_handle,PauseMode := 0)
    }
    Upkeep(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        return this._curl_easy_upkeep(easy_handle)
    }
    ; UrlEscape(){
    ;     ;todo - write a Unicode-aware string escaper
    ; }
    ; UrlUnescape(){

    ; }

	SetHeaders(headersArrayOrMap,easy_handle?) {    ;Sets custom HTTP headers for request.
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle

        ; Pass an array of "Header: value" strings OR a Map of the same.
        ; Use empty value ("Header: ") to disable internally used header.
        ; Use semicolon ("Header;") to add the header with no value.
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

    SetPost(sourceData,handle?){    ;properly encapsulates data to be POSTed
        ;you can pass:
        ;   -normal text/numbers
        ;   -a File object to upload as binary
        ;   -an Object/Array/Map to dump as JSON

        ;NOTE: the file is currently read completely into memory before being sent
        ;todo - create callback that reads POSTed file incrementally

        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        this.easyHandleMap[easy_handle]["postData"] := unset    ;clears last POST. prolly redundant but eh.

        switch Type(sourceData) {
            case "String","Integer":
                this.easyHandleMap[easy_handle]["postData"] := this._StrBuf(sourceData)
            case "Object","Array","Map":
                this.easyHandleMap[easy_handle]["postData"] := this._StrBuf(json.dump(sourceData))
            case "File":
                this.easyHandleMap[easy_handle]["postData"] := Buffer(sourceData.length)  ;create the buffer with the right size
                sourceData.RawRead(this.easyHandleMap[easy_handle]["postData"]) ;read the file into the buffer
                this.SetOpt("POSTFIELDSIZE_LARGE",sourceData.length)
            case "Buffer":
                this.easyHandleMap[easy_handle]["postData"] := sourceData
                this.SetOpt("POSTFIELDSIZE_LARGE",sourceData.size)
            Default:
                throw ValueError("Unknown object type passed as POST data: " Type(sourceData))
        }
        this.SetOpt("POSTFIELDS",this.easyHandleMap[easy_handle]["postData"])

        /*
            "File" currently uses this method:
            curl -X POST "https://httpbin.org/post" -H "accept: application/json" --data-binary "@07.binary.upload.zip"

            and currently does not use:
            curl -X POST "https://httpbin.org/post" -H "accept: application/json" -F "file=@07.binary.upload.zip"

            todo - investigate if there's a need to differentiate between them.
        */
    }


    ;Base64 operations
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

    UrlInit(){
        url_handle := this._curl_url()
        this.urlHandleMap[0].push(url_handle) ;urlHandleMap[0][-1] is a dynamic reference to the last created url_handle
        this.urlHandleMap[url_handle] := Map() 
        this.urlHandleMap[url_handle]["url_handle"] := url_handle
        this.urlHandleMap[url_handle]["timestamp"] := A_NowUTC
        return url_handle
    }
    UrlCleanup(url_handle?){
        url_handle ??= (this.urlHandleMap[0][-1])   ;defaults to the last created url_handle
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
        url_handle ??= this.urlHandleMap[0][-1]   ;defaults to the last created url_handle
        newUrl := this._curl_url_dup(url_handle)
        this.urlHandleMap[0].push(newUrl)
        this.urlHandleMap[newUrl] := this._DeepClone(this.urlHandleMap[url_handle])
        this.urlHandleMap[newUrl]["timestamp"] := A_NowUTC
    }

    UrlSet(part,content,flags := [],url_handle?){
        url_handle ??= this.urlHandleMap[0][-1]   ;defaults to the last created url_handle

        flagBitmask := 0
        for k,v in flags
            flagBitmask += this.constants["CURLUflags"][v]

        partConstant := this.constants["CURLUPart"][part]
        return this._curl_url_set(url_handle,partConstant,content,flagBitmask)
    }
    UrlGet(part,flags := [], url_handle?){
        url_handle ??= this.urlHandleMap[0][-1]   ;defaults to the last created url_handle

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
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle
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
        this.multiHandleMap[0].push(multi_handle) ;multiHandleMap[0][-1] is a dynamic reference to the last created multi_handle
        this.multiHandleMap[multi_handle] := Map()
        this.multiHandleMap[multi_handle]["associatedEasyHandles"] := []
        return multi_handle
    }
    AddEasyToMulti(easy_handle?,multi_handle?){ ;auto-invoked during EasyInit()
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle
        ret := this._curl_multi_add_handle(multi_handle,easy_handle)
        this.easyHandleMap[easy_handle]["associated_multi_handle"] := multi_handle
        ; this.multiHandleMap["pending_callbacks"].push(easy_handle)
        return ret
    }
    RemoveEasyFromMulti(easy_handle?,multi_handle?) {
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle
        ret := this._curl_multi_remove_handle(multi_handle,easy_handle)
        this.easyHandleMap[easy_handle]["associated_multi_handle"] := unset
        return ret
    }
    SwapMultiPools(easyHandleArr,oldMultiHandle,newMultiHandle){   ;used to transfer easy_handles between multi_handles
        for k,v in easyHandleArr{   ;array of easy_handles
            this.RemoveEasyFromMulti(v,oldMultiHandle)
            this.AddEasyToMulti(v,newMultiHandle)
        }
    }
    GetInfo(infoOption,curl_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        result := this._curl_easy_getinfo(easy_handle,infoOption,&info := 0)

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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        static c := this.constants["CURLH_ORIGINS"]
        origin ??= c["HEADER"]

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
                    ; list .= "`n" this.%self%(v,depth-1,indentLevel  "    ")
                    list .= "`n" this.PrintObj(v,depth-1,indentLevel  "    ")
                case "Buffer","LibQurl.Storage.MemBuffer":
                    list .= " => [BUFFER] "
                case "File":
                    list .= " => [FILE] "
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
        old_easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
;#compile:helper
;#compile:_struct
;#compile:storage
;#compile:_declareConstants
;#compile:dll
}