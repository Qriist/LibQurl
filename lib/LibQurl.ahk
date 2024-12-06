#requires Autohotkey v2.1-alpha.9
#Include "*i <Aris\G33kDude\cJson>"
class LibQurl {
    ;core functionality
    __New() {
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
        this.struct := LibQurl._struct()  ;holds the various structs
        this.writeRefs := Map()    ;holds the various write handles
        this.constants := Map()
        this.CURL_ERROR_SIZE := 256
    }
    register(dllPath?,preconfigureSSL?) {
        if !FileExist(dllPath)
            dllPath := this._findDLLfromAris()  ;will try to fallback on the installed package directory
        if !FileExist(dllPath)
            throw ValueError("libcurl DLL not found!", -1, dllPath)
        this.curlDLLpath := dllpath
        this.curlDLLhandle := DllCall("LoadLibrary", "Str", dllPath, "Ptr")   ;load the DLL into resident memory
        ;this._curl_global_sslset   -todo
        this._curl_global_init()
        this._declareConstants()
        this._buildOptMap()
        this.VersionInfo := this.GetVersionInfo()
        this.UrlInit()
        this.MultiInit()
        return this.Init()
    }
    Init(multi_handle?){
        ; multi_handle ??= this.multiHandleMap[0][-1] ;defaults to the last created multi_handle
        easy_handle := this._curl_easy_init()
        this.easyHandleMap[0].push(easy_handle) ;easyHandleMap[0][-1] is a dynamic reference to the last created easy_handle
        this.easyHandleMap[easy_handle] := Map() 

        If !this.easyHandleMap[easy_handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)

        this.easyHandleMap[easy_handle]["easy_handle"] := easy_handle
        this.easyHandleMap[easy_handle]["options"] := Map()  ;prepares option storage
        this.SetOpt("ACCEPT_ENCODING","",easy_handle)    ;enables compressed transfers without affecting input headers
        this.SetOpt("FOLLOWLOCATION",1,easy_handle)    ;allows curl to follow redirects
        this.SetOpt("MAXREDIRS",30,easy_handle)    ;limits redirects to 30 (matches recent curl default)

        ; this.AddEasyToMulti(easy_handle,multi_handle)
        ; this.easyHandleMap[easy_handle]["associated_multi_handle"] := multi_handle
        ; msgbox this.easyHandleMap[easy_handle]["associated_multi_handle"]

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
    ShowOB(ob, strOB := "") {  ; returns `n list.  pass object, returns list of elements. nice chart format with `n.  strOB for internal use only.
        (Type(Ob) ~= 'Object|Gui') ? Ob := Ob.OwnProps() : 1
        for i, v in ob
        (!isobject(v)) ? (rets .= "`n [" strOB i "] = [" v "]") : (rets .= this.ShowOB(v, strOB i "."))
        return isSet(rets) ? rets : ""
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
    _RefreshEasyHandleForAsync(easy_handle?){    ;this soft-resets the handle without breaking the connection
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
        ; this._prepareInitCallbacks(easy_handle)
        ; this._setCallbacks(1,1,1,1,,easy_handle) ;don't enable debug by default
        this.HeaderToMem(0,easy_handle)    ;automatically save lastHeader to memory
        
        ;todo - gather and clean the SetOpts
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
        ; msgbox this.ShowOB(retObj)
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

        If (this.constants["CURLINFO"][infoOption]["infoType"] = "STRING")
            info := StrGet(info,"UTF-8")
        
        return info
    }

    ;dummied code that doesn't work right yet


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
    _buildOptMap() {    ;creates a reference matrix of all known SETCURLOPTs
        this.Opt.CaseSense := "Off"
        optPtr := 0
        argTypes := Map(0, Map("type", "Int", "easyType", "CURLOT_LONG")
                    ,   1, Map("type", "Int", "easyType", "CURLOT_VALUES")
                    ,   2, Map("type", "Int64", "easyType", "CURLOT_OFF_T")
                    ,   3, Map("type", "Ptr", "easyType", "CURLOT_OBJECT")
                    ,   4, Map("type", "Astr", "easyType", "CURLOT_STRING")
                    ,   5, Map("type", "Ptr", "easyType", "CURLOT_SLIST")
                    ,   6, Map("type", "Ptr", "easyType", "CURLOT_CBPTR")
                    ,   7, Map("type", "Ptr", "easyType", "CURLOT_BLOB")
                    ,   8, Map("type", "Ptr", "easyType", "CURLOT_FUNCTION"))
        
        Loop {
            optPtr := this._curl_easy_option_next(optPtr)
            if (optPtr = 0)
                break
            o := this.struct.curl_easyoption(optPtr)
            /*
                ;types defined in v1 class  *rearranged to follow typedef enum*
                LONG :=     0 + AHK_ARG * 1  ; Long
                BITS := LONG                 ; Long argument with a set of values/bitmask
                OFFT := 30000 + AHK_ARG * 6  ; Curl_off_t (Int64)
                OBJP := 10000 + AHK_ARG * 2  ; Object pointer
                STRP := 10000 + AHK_ARG * 3  ; String pointer
                SLIP := 10000 + AHK_ARG * 4  ; Linked-list pointer
                CBPT := OBJP                 ; Argument pointer passed to callback
                BLOB := 40000 + AHK_ARG * 7  ; Blob struct pointer
                FUNP := 20000 + AHK_ARG * 5  ; Function pointer
            
                {LONG:"Int"
                ,   OBJECTPOINT:"Ptr"
                ,   STRINGPOINT:"Astr"
                ,   FUNCTIONPOINT:"Ptr"
                ,   OFF_T:"Int64"
                ,   BLOB:"Ptr"}
            */
    
            o["type"] := argTypes[o["rawCurlType"]]["type"]
            o["easyType"] := argTypes[o["rawCurlType"]]["easyType"]
     
            this.Opt[o["name"]] := o
            If !this.OptById.Has(o["id"])   ;the DLL was giving an errorneous "ENCODING" option, maybe others, idk
                this.OptById[o["id"]] := o["name"]
        }
        ; msgbox this.ShowOB(this.opt)
    }
    
    _setCallbacks(body?,header?,read?,progress?,debug?,easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
    
        ;todo - read/progress/debug callbacks
    
        
        if IsSet(body){
            CBF := this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"]
            if IsInteger(CBF){  ;checks if this callback already exists
                this.writeRefs[CBF] -= 1    ;decrement the reference tracker
                CallbackFree(CBF)
                (CBF=0?this.writeRefs.delete(CBF):"")   ;remove key if done with it
            }
    
            this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"] := CBF := CallbackCreate(
                (dataPtr, size, sizeBytes, userdata) =>
                this._writeCallbackFunction(dataPtr, size, sizeBytes, userdata, easy_handle)
            )
    
            ;creates or increments the tracking key
            ; If !this.writeRefs.Has(CBF)
                this.writeRefs[CBF] := 1
            ; else
                ; this.writeRefs[CBF] += 1
        }
    
    
        if IsSet(header){
            CBF := this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"]
            if IsInteger(CBF){  ;checks if this callback already exists
                this.writeRefs[CBF] -= 1    ;decrement the reference tracker
                CallbackFree(CBF)
                (CBF=0?this.writeRefs.delete(CBF):"")   ;remove key if done with it
            }
            ; if IsInteger(this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"])
            ;     CallbackFree(this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"])
            this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"] := CBF := CallbackCreate(
                (dataPtr, size, sizeBytes, userdata) =>
                this._headerCallbackFunction(dataPtr, size, sizeBytes, userdata, easy_handle)
            )
            
            ;creates or increments the tracking key
            ; If !this.writeRefs.Has(CBF)
                this.writeRefs[CBF] := 1
            ; else
                ; this.writeRefs[CBF] += 1
        }
        ; if IsSet(read)
        ; if IsSet(progress)
        ; if IsSet(debug)
        
        
        ;non-lambda rewrite
        ;   actualCallbackFunction(dataPtr, size, sizeBytes, userdata) {
        ;     return this._writeCallbackFunction(dataPtr, size, sizeBytes, userdata, passed_curl_handle)
        ;   }
        ;   this.easyHandleMap[easy_handle]["writeCallbackFunction"] := CallbackCreate(actualCallbackFunction)
        ; Curl._CB_Header   := CallbackCreate(Curl._HeaderCallback)
        ; Curl._CB_Read     := CallbackCreate(Curl._ReadCallback)
        ; Curl._CB_Progress := CallbackCreate(Curl._ProgressCallback)
        ; Curl._CB_Debug    := CallbackCreate(Curl._DebugCallback)
    }
    
    ; Callbacks
    ; =========
    _writeCallbackFunction(dataPtr, size, sizeBytes, userdata, easy_handle) {
        dataSize := size * sizeBytes
        return this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].RawWrite(dataPtr, dataSize)
    }
    
    _headerCallbackFunction(dataPtr, size, sizeBytes, userdata, easy_handle) {
        dataSize := size * sizeBytes
        ; msgbox type(this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"])
        Return this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].RawWrite(dataPtr, dataSize)
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
    
    _DeepClone(obj) {    ;https://github.com/thqby/ahk2_lib/blob/master/deepclone.ahk
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
    
    _ErrorHandler(callingMethod,invokedCurlFunction,curlErrorCodeType,incomingValue?){
        If (curlErrorCodeType = "Curlcode") {
    
        } else if (curlErrorCodeType = "Curlmcode") {
    
        } else if (curlErrorCodeType = "Curlshcode") {
    
        } else if (curlErrorCodeType = "Curlucode") {
    
        } else if (curlErrorCodeType = "Curlhcode") {
    
        }
    }
    
    ; Returns a Buffer object containing the string.
    _StrBuf(str, encoding := "cp0")
    {
        ; Calculate required size and allocate a buffer.
        buf := Buffer(StrPut(str, encoding))
        ; Copy or convert the string.
        StrPut(str, buf, encoding)
        return buf
    }
    
    
    
    _HasVal(inObj,needle){  ;return the first key with a matching input value
        for k,v in (Type(inObj)!="Object"?inObj:inObj.OwnProps()) { ;itemize Objects if required
            If (v = needle)
                return k
        }
        return unset
    }
    _Perform(easy_handle?){
        easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
    
        ; this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].Open()
        ; this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].Open()
        retcode := this._curl_easy_perform(easy_handle)
    
        /*
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].Close()
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].Close()
        ;accessibly attach body to easy_handle output
        bodyObj := this.easyHandleMap[easy_handle]["callbacks"]["body"]
        lastBody := (bodyObj["writeType"]="memory"?bodyObj["writeTo"]:FileOpen(bodyObj["filename"],"rw"))
        this.easyHandleMap[easy_handle]["lastBody"] := lastBody
    
        ;accessibly attach headers to easy_handle output
        headerObj := this.easyHandleMap[easy_handle]["callbacks"]["header"]
        lastHeaders := (headerObj["writeType"]="memory"?headerObj["writeTo"]:FileOpen(headerObj["filename"],"rw"))
        this.easyHandleMap[easy_handle]["lastHeaders"] := lastHeaders
        */
       
        this._performCleanup(easy_handle)
        this.HeaderToMem(0,easy_handle) ;resets the header buffer
        this.WriteToMem(0,easy_handle) ;resets the header buffer
        ;todo - write an "output to null" callback function for more safely reseting file writes
        return retCode
    }
    
    _performCleanup(easy_handle){
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].Close()
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].Close()
        ;accessibly attach body to easy_handle output
        bodyObj := this.easyHandleMap[easy_handle]["callbacks"]["body"]
        lastBody := (bodyObj["writeType"]="memory"?bodyObj["writeTo"]:FileOpen(bodyObj["filename"],"rw"))
        this.easyHandleMap[easy_handle]["lastBody"] := lastBody
    
        ;accessibly attach headers to easy_handle output
        headerObj := this.easyHandleMap[easy_handle]["callbacks"]["header"]
        lastHeaders := (headerObj["writeType"]="memory"?headerObj["writeTo"]:FileOpen(headerObj["filename"],"rw"))
        this.easyHandleMap[easy_handle]["lastHeaders"] := lastHeaders
    }
    ; _QueryPerformanceCounter(){
    ;     ; https://learn.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
    ;     liPerformanceCount := Buffer(8)
    ;     DllCall("QueryPerformanceCounter", "Ptr", liPerformanceCount)
    ;     return NumGet(liPerformanceCount, 0, "Int64")
    ; }
    _findDLLfromAris(){ ;dynamically finds the dll from a versioned Aris installation
        If !FileExist(A_ScriptDir "\lib\Aris\Qriist\LibQurl.ahk")
            return unset
        packageDir := A_ScriptDir "\lib\Aris\Qriist"
        loop files (packageDir "\LibQurl@*") , "D"{
            LQdir := packageDir "\" A_LoopFileName
        }
        return LQdir "\bin\libcurl-x64.dll"
    }

    class _struct {
        walkPtrArray(inPtr) {
            retObj := []
            loop {
                pFeature := NumGet(inPtr + ((A_Index - 1) * A_PtrSize), "Ptr")
                if (pFeature = 0) {
                    break
                }
                retObj.push(StrGet(pFeature, "UTF-8"))
            }
            return retObj
        }
        curl_easyoption(ptr) {
            return Map("name",StrGet(numget(ptr, "Ptr"), "CP0")
                ,   "id", numget(ptr, 8, "UInt")
                ,   "rawCurlType", numget(ptr, 12, "UInt")
                ,   "flags", numget(ptr, 16, "UInt"))
        }
        curl_version_info_data(ptr){
            ;build initial struct map
            retObj := Map()
            retObj["age"] := NumGet(ptr,(Offset := 0),"Int") + 1 ;intentionally +1
            retObj["version"] := StrGet(NumGet(ptr,8,"Ptr"),"UTF-8")
            retObj["version_num"] := NumGet(ptr,16,"UInt")
            retObj["host"] := StrGet(NumGet(ptr,24,"Ptr"),"UTF-8")
            retObj["features"] := NumGet(ptr,32,"UInt")
            retObj["ssl_version"] := StrGet(NumGet(ptr,40,"Ptr"),"UTF-8")
            retObj["ssl_version_num"] := NumGet(ptr,48,"UInt")
            retObj["libz_version"] := StrGet(NumGet(ptr,56,"Ptr"),"UTF-8")
            retObj["protocols"] := this.walkPtrArray(NumGet(ptr,64,"Ptr"))
    
            ;walk through optional struct members
            If (retObj["age"] >= 2) {
                retObj["ares"] := str(ptr,72)
                retObj["ares"] := NumGet(ptr,80,"Int")
            }
            If (retObj["age"] >= 3) {
                retObj["libidn"] := str(ptr,88)
            }
            If (retObj["age"] >= 4) {
                retObj["iconv_ver_num"] := NumGet(ptr, 96, "Int")
                retObj["libssh_version"] := str(ptr,104)
            }
            If (retObj["age"] >= 5) {
                retObj["brotli_ver_num"] := NumGet(ptr, 112, "Int")
                retObj["brotli_version"] := str(ptr, 120)
            }
            If (retObj["age"] >= 6) {
                retObj["nghttp2_version"] := NumGet(ptr, 128, "UInt")
                retObj["nghttp2"] := str(ptr,136)
                retObj["quic_version"] := str(ptr,144)
            }
            If (retObj["age"] >= 7) {
                retObj["cainfo"] := str(ptr,152)
                retObj["capath"] := str(ptr,160)   
            }
            If (retObj["age"] >= 8) {
                retObj["zstd_ver_num"] := NumGet(ptr,168,"Int")
                retObj["zstd_version"] := str(ptr,176)
            }
            If (retObj["age"] >= 9) {
                retObj["hyper_version"] := str(ptr,184)
            }
            If (retObj["age"] >= 10) {
                retObj["gsasl_version"] := str(ptr,192)
            }
            If (retObj["age"] >= 11) {
                retObj["feature_names"] := this.walkPtrArray(NumGet(ptr,200,"Ptr"))
            }
            return retObj
            str(ptr,offset,encoding := "UTF-8"){
                return (NumGet(ptr,offset,"Ptr")=0?0:StrGet(NumGet(ptr,offset,"Ptr"),encoding))
            }
        }
        curl_CURLMsg(ptr){
            retObj := Map()
            retObj["msg"] := NumGet(ptr,0,"UInt")
            retObj["easy_handle"] := NumGet(ptr,8,"Ptr")
            retObj["result"] := NumGet(ptr,12,"Int")
            ; msgbox ""
            ;     .   "msg: " retObj["msg"] "`n"
            ;     .   "easy_handle: " retObj["easy_handle"] "`n"
            ;     .   "result: " retObj["result"] "`n"
                return retObj
        }
    }

    Class Storage {
        ; Wrapper for file. Shouldn't be used directly.
        
        Class File {
            __New(filename, &handleMap, storageCategory, accessMode := "w", easy_handle?) {
                this.easyHandleMap := handleMap
                easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
                
                this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                this.writeObj["writeType"] := "file"
                this.writeObj["filename"] := filename
                this.writeObj["accessMode"] := accessMode
                this.writeObj["writeTo"] := ""
                this.writeObj["curlHandle"] := easy_handle
                this.storageCategory := storageCategory
                this.Open()
                ; ; User callbacks
                ; this.OnWrite    := ""
                ; this.OnRead     := ""
                ; this.OnHeader   := ""
                ; this.OnProgress := ""
                ; this.OnDebug    := ""
                
                ; ; Input/output
                ; this._writeTo  := ""
                ; this._headerTo := ""
                ; this._readFrom := ""
            }
    
            Open() {
                If (this.writeObj["accessMode"] == "w") {
                    SplitPath(this.writeObj["filename"], , &fileDirPath)
                    If fileDirPath
                        DirCreate fileDirPath
                    this.writeObj["writeTo"] := FileOpen(this.writeObj["filename"], this.writeObj["accessMode"], "CP0")
                    ;associates the write object with the curl easy_handle
                    ; this.easyHandleMap["assoc"][this.writeObj["writeTo"].easy_handle] := this.getCurlHandle()
                    ; msgbox this.easyHandleMap["assoc"][this.getHandle()]
                }
            }
    
            Close() {
                this.writeObj["writeTo"].Close()
                ; this.easyHandleMap["assoc"].Delete(this.writeObj["writeTo"].easy_handle)
            }
    
            Write(data) {
                ; If (this._fileObject == "")
                ; 	Return -1
                Return this.writeObj["writeTo"].Write(data)
            }
    
            RawWrite(srcDataPtr, srcDataSize) {
                ; If (this._fileObject == "")
                ; || (this._accessMode != "w")
                ; 	Return -1
                Return this.writeObj["writeTo"].RawWrite(srcDataPtr+0, srcDataSize)
            }
    
            getCurlHandle() {
                return this.writeObj["curlHandle"]
            }
    
            RawRead(dstDataPtr, dstDataSize) {
            ; 	If (this._fileObject == "")
            ; 	|| (this._accessMode != "r")
            ; 		Return -1
    
                Return this.writeObj["writeTo"].RawRead(dstDataPtr+0, dstDataSize)
            }
    
            Seek(offset, origin := 0) {
                Return !(this.writeObj["writeTo"].Seek(offset, origin))
            }
        }
    
        Class MemBuffer {
        ; Wrapper for memory buffer, similar to regular FileObject
            __New(dataPtr := 0, maxCapacity?, dataSize := 0, &handleMap?, storageCategory?, easy_handle?) {
                ; this._data     := ""
                this._dataPos  := 0
                this.easyHandleMap := handleMap
                easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
                ; msgbox easy_handle
    
                this.easy_handle := easy_handle
                this.storageCategory := storageCategory
                this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                this.writeObj["writeType"] := "memory"
    
                If !IsSet(maxCapacity) || (maxCapacity = 0)
                   maxCapacity := 50*1024**2  ; 50 Mb
                    ; maxCapacity := 1000  ; 50 Mb
    
                maxCapacity := Max(maxCapacity, dataSize)
                ; msgbox maxCapacity
                this.writeObj["maxCapacity"] := maxCapacity
                this.writeObj["writeTo"] := Buffer(maxCapacity)
    
                ; msgbox "New " ObjPtr(this.writeObj["writeTo"])
                ; MsgBox maxCapacity "`n" this.writeObj["writeTo"].Ptr
                ; this.writeObj["writeTo"].Ptr := this.writeObj["writeTo"]
                ; this.writeObj["writeTo"] := Buffer(maxCapacity)
                this.writeObj["curlHandle"] := easy_handle
                this.writeObj["interimPtr"] := 0
                
    
    
    
                If (dataPtr != 0) {
                    this._dataMax  := maxCapacity
                    this._dataSize := dataSize
                    this._dataPtr  := dataPtr
                } Else
                ; No argument, store inside class.
                {
                    this._dataSize := 0
                    this._dataMax  := ObjSetCapacity(this.writeObj["writeTo"], maxCapacity)
                    this._dataPtr  := 0 ;ObjGetAddress(this._data)
                    ; msgbox this._dataMax
                }
            }
    
            Open() {
                ; Do nothing
            }
    
            Close() {
                
                ; this.easyHandleMap[this.easy_handle]["lastHeaders"] := this.writeObj["writeTo"]
                ; msgbox strget(this.writeObj["writeTo"],"UTF-8")
            }
    
            ; Write(data) {
            ; 	srcDataSize := StrPut(srcText, "CP0")
    
            ; 	If ((this._dataPos + srcDataSize) > this._dataMax)
            ; 		Return -1
    
            ; 	StrPut(data, this._dataPtr + this._dataPos, "CP0")
    
            ; 	this._dataPos  += srcDataSize
            ; 	this._dataSize := Max(this._dataSize, this._dataPos)
    
            ; 	Return srcDataSize
            ; }
    
            RawWrite(srcDataPtr, srcDataSize) {
                Offset := this._dataPtr
                DllCall("ntdll\memcpy"
                    , "Ptr" , this.writeObj["writeTo"].Ptr + Offset
                    , "Ptr" , srcDataPtr+0
                    , "Int" , srcDataSize)
                this._dataSize := this._dataPtr += srcDataSize
                Return srcDataSize
            }
    
            ; GetAsText(encoding := "UTF-8") {
            ; 	isEncodingWide := ((encoding = "UTF-16") || (encoding = "CP1200"))
            ; 	textMaxLength  := this._dataSize / (isEncodingWide ? 2 : 1)
            ; 	Return StrGet(this._dataPtr, textMaxLength, encoding)
            ; }
    
            ; RawRead(dstDataPtr, dstDataSize) {
            ; 	dataLeft := this._dataSize - this._dataPos
            ; 	dstDataSize := Min(dstDataSize, dataLeft)
    
            ; 	DllCall("ntdll\memcpy"
            ; 	, "Ptr" , dstDataPtr
            ; 	, "Ptr" , this._dataPtr + this._dataPos
            ; 	, "Int" , dstDataSize)
    
            ; 	Return dstDataSize
            ; }
    
            ; Seek(offset, origin := 0) {
            ; 	newDataPos := offset
            ; 	+ ( (origin == 0) ? 0               ; SEEK_SET
            ; 	  : (origin == 1) ? this._dataPos   ; SEEK_CUR
            ; 	  : (origin == 2) ? this._dataSize  ; SEEK_END
            ; 	  : 0 )                             ; Unknown 'origin', use SEEK_SET
    
            ; 	If (newDataPos > this._dataSize)
            ; 	|| (newDataPos < 0)
            ; 		Return 1  ; CURL_SEEKFUNC_FAIL
    
            ; 	this._dataPos := newDataPos
            ; 	Return 0  ; CURL_SEEKFUNC_OK
            ; }
    
            ; Tell() {
            ; 	Return this._dataPos
            ; }
    
            Length() {
                Return this._dataSize
            }
        }
    }

    _declareConstants(){
    
        this.constants["CURLUPart"] := c := Map()
        c.CaseSense := 0
        c["URL"] := 0
        c["SCHEME"] := 1
        c["USER"] := 2
        c["PASSWORD"] := 3
        c["OPTIONS"] := 4
        c["HOST"] := 5
        c["PORT"] := 6
        c["PATH"] := 7
        c["QUERY"] := 8
        c["FRAGMENT"] := 9
        c["ZONEID"] := 10
    
        this.constants["CURLUflags"] := c := Map()
        c.CaseSense := 0
        c["DEFAULT_PORT"] := 1 << 0
        c["NO_DEFAULT_PORT"] := 1 << 1
        c["DEFAULT_SCHEME"] := 1 << 2
        c["NON_SUPPORT_SCHEME"] := 1 << 3
        c["PATH_AS_IS"] := 1 << 4
        c["DISALLOW_USER"] := 1 << 5
        c["URLDECODE"] := 1 << 6
        c["URLENCODE"] := 1 << 7
        c["APPENDQUERY"] := 1 << 8
        c["GUESS_SCHEME"] := 1 << 9
        c["NO_AUTHORITY"] := 1 << 10
        c["ALLOW_SPACE"] := 1 << 11
        c["PUNYCODE"] := 1 << 12
        c["PUNY2IDN"] := 1 << 13
    
        this.constants["CURLINFO_offsets"] := o := Map()   
        o.CaseSense := 0
        o["STRING"] := Map("offset",0x100000,"infoType","STRING","dllType","Ptr*")  ;good
        o["LONG"] := Map("offset",0x200000,"infoType","LONG","dllType","Int*")  ;good
        o["DOUBLE"] := Map("offset",0x300000,"infoType","DOUBLE","dllType","Double*")   ;good
        o["SLIST"] := Map("offset",0x400000,"infoType","SLIST","dllType","Ptr*")
        o["PTR"] := Map("offset",0x400000,"infoType","PTR","dllType","Ptr*")
        o["SOCKET"] := Map("offset",0x500000,"infoType","SOCKET","dllType","Ptr*")
        o["OFF_T"] := Map("offset",0x600000,"infoType","OFF_T","dllType","Ptr*")    ;good
        o["MASK"] := Map("offset",0x0fffff,"infoType","MASK","dllType","Ptr*")
        o["TYPEMASK"] := Map("offset",0xf00000,"infoType","TYPEMASK","dllType","Ptr*")
    
        offsetGroup := "CURLINFO_offsets"    
        this.constants["CURLINFO"] := c := Map()
        c.CaseSense := 0
        c["EFFECTIVE_URL"] :=               bindOffsets(offsetGroup, 1, "STRING")
        c["RESPONSE_CODE"] :=               bindOffsets(offsetGroup, 2, "LONG")
        c["TOTAL_TIME"] :=                  bindOffsets(offsetGroup, 3, "DOUBLE")
        c["NAMELOOKUP_TIME"] :=             bindOffsets(offsetGroup, 4, "DOUBLE")
        c["CONNECT_TIME"] :=                bindOffsets(offsetGroup, 5, "DOUBLE")
        c["PRETRANSFER_TIME"] :=            bindOffsets(offsetGroup, 6, "DOUBLE")
        c["SIZE_UPLOAD_T"] :=               bindOffsets(offsetGroup, 7, "OFF_T")
        c["SIZE_DOWNLOAD_T"] :=             bindOffsets(offsetGroup, 8, "OFF_T")
        c["SPEED_DOWNLOAD_T"] :=            bindOffsets(offsetGroup, 9, "OFF_T")
        c["SPEED_UPLOAD_T"] :=              bindOffsets(offsetGroup, 10, "OFF_T")
        c["HEADER_SIZE"] :=                 bindOffsets(offsetGroup, 11, "LONG")
        c["REQUEST_SIZE"] :=                bindOffsets(offsetGroup, 12, "LONG")
        c["SSL_VERIFYRESULT"] :=            bindOffsets(offsetGroup, 13, "LONG")
        c["FILETIME"] :=                    bindOffsets(offsetGroup, 14, "LONG")
        c["FILETIME_T"] :=                  bindOffsets(offsetGroup, 14, "OFF_T")
        c["CONTENT_LENGTH_DOWNLOAD_T"] :=   bindOffsets(offsetGroup, 15, "OFF_T")
        c["CONTENT_LENGTH_UPLOAD_T"] :=     bindOffsets(offsetGroup, 16, "OFF_T")
        c["STARTTRANSFER_TIME"] :=          bindOffsets(offsetGroup, 17, "DOUBLE")
        c["CONTENT_TYPE"] :=                bindOffsets(offsetGroup, 18, "STRING")
        c["REDIRECT_TIME"] :=               bindOffsets(offsetGroup, 19, "DOUBLE")
        c["REDIRECT_COUNT"] :=              bindOffsets(offsetGroup, 20, "LONG")
        c["PRIVATE"] :=                     bindOffsets(offsetGroup, 21, "STRING")
        c["HTTP_CONNECTCODE"] :=            bindOffsets(offsetGroup, 22, "LONG")
        c["HTTPAUTH_AVAIL"] :=              bindOffsets(offsetGroup, 23, "LONG")
        c["PROXYAUTH_AVAIL"] :=             bindOffsets(offsetGroup, 24, "LONG")
        c["OS_ERRNO"] :=                    bindOffsets(offsetGroup, 25, "LONG")
        c["NUM_CONNECTS"] :=                bindOffsets(offsetGroup, 26, "LONG")
        c["SSL_ENGINES"] :=                 bindOffsets(offsetGroup, 27, "SLIST")
        c["COOKIELIST"] :=                  bindOffsets(offsetGroup, 28, "SLIST")
        c["FTP_ENTRY_PATH"] :=              bindOffsets(offsetGroup, 30, "STRING")
        c["REDIRECT_URL"] :=                bindOffsets(offsetGroup, 31, "STRING")
        c["PRIMARY_IP"] :=                  bindOffsets(offsetGroup, 32, "STRING")
        c["APPCONNECT_TIME"] :=             bindOffsets(offsetGroup, 33, "DOUBLE")
        c["CERTINFO"] :=                    bindOffsets(offsetGroup, 34, "PTR")
        c["CONDITION_UNMET"] :=             bindOffsets(offsetGroup, 35, "LONG")
        c["RTSP_SESSION_ID"] :=             bindOffsets(offsetGroup, 36, "STRING")
        c["RTSP_CLIENT_CSEQ"] :=            bindOffsets(offsetGroup, 37, "LONG")
        c["RTSP_SERVER_CSEQ"] :=            bindOffsets(offsetGroup, 38, "LONG")
        c["RTSP_CSEQ_RECV"] :=              bindOffsets(offsetGroup, 39, "LONG")
        c["PRIMARY_PORT"] :=                bindOffsets(offsetGroup, 40, "LONG")
        c["LOCAL_IP"] :=                    bindOffsets(offsetGroup, 41, "STRING")
        c["LOCAL_PORT"] :=                  bindOffsets(offsetGroup, 42, "LONG")
        c["ACTIVESOCKET"] :=                bindOffsets(offsetGroup, 44, "SOCKET")
        c["TLS_SSL_PTR"] :=                 bindOffsets(offsetGroup, 45, "PTR")
        c["HTTP_VERSION"] :=                bindOffsets(offsetGroup, 46, "LONG")
        c["PROXY_SSL_VERIFYRESULT"] :=  bindOffsets(offsetGroup, 47, "LONG")
        c["SCHEME"] :=                      bindOffsets(offsetGroup, 49, "STRING")
        c["TOTAL_TIME_T"] :=                bindOffsets(offsetGroup, 50, "OFF_T")
        c["NAMELOOKUP_TIME_T"] :=           bindOffsets(offsetGroup, 51, "OFF_T")
        c["CONNECT_TIME_T"] :=              bindOffsets(offsetGroup, 52, "OFF_T")
        c["PRETRANSFER_TIME_T"] :=          bindOffsets(offsetGroup, 53, "OFF_T")
        c["STARTTRANSFER_TIME_T"] :=        bindOffsets(offsetGroup, 54, "OFF_T")
        c["REDIRECT_TIME_T"] :=             bindOffsets(offsetGroup, 55, "OFF_T")
        c["APPCONNECT_TIME_T"] :=           bindOffsets(offsetGroup, 56, "OFF_T")
        c["RETRY_AFTER"] :=                 bindOffsets(offsetGroup, 57, "OFF_T")
        c["EFFECTIVE_METHOD"] :=            bindOffsets(offsetGroup, 58, "STRING")
        c["PROXY_ERROR"] :=                 bindOffsets(offsetGroup, 59, "LONG")
        c["REFERER"] :=                     bindOffsets(offsetGroup, 60, "STRING")
        c["CAINFO"] :=                      bindOffsets(offsetGroup, 61, "STRING")
        c["CAPATH"] :=                      bindOffsets(offsetGroup, 62, "STRING")
        c["XFER_ID"] :=                     bindOffsets(offsetGroup, 63, "OFF_T")
        c["CONN_ID"] :=                     bindOffsets(offsetGroup, 64, "OFF_T")
        c["QUEUE_TIME_T"] :=                bindOffsets(offsetGroup, 65, "OFF_T")
        c["LASTONE"] :=                     bindOffsets(offsetGroup, 65, "OFF_T")
    
    
        /*
        c["NONE"] := unset  ;just here for parity with the source
        ; c["EFFECTIVE_URL"] := bindOffsets(c,o,g,"STRING")
        c["EFFECTIVE_URL"] := Map("id", o["STRING"] + 1, "infoType", "STRING", "dllType", "Ptr*")
        c["RESPONSE_CODE"] := Map("id", o["LONG"] + 2, "infoType", "LONG", "dllType", "Int*")
        c["TOTAL_TIME"] := Map("id", o["DOUBLE"] + 3, "infoType", "DOUBLE", "dllType", "Ptr")
        c["NAMELOOKUP_TIME"] := Map("id", o["DOUBLE"] + 4, "infoType", "DOUBLE", "dllType", "Double*")
        c["CONNECT_TIME"] := Map("id", o["DOUBLE"] + 5, "infoType", "DOUBLE", "dllType", "Double*")
        c["PRETRANSFER_TIME"] := Map("id", o["DOUBLE"] + 6, "infoType", "DOUBLE", "dllType", "Double*")
        c["SIZE_UPLOAD"] := Map("id", o["DOUBLE"] + 7, "infoType", "DOUBLE", "dllType", "Double*")
        c["SIZE_UPLOAD_T"] := Map("id", o["OFF_T"] + 7, "infoType", "OFF_T", "dllType", "Int*")
        c["SIZE_DOWNLOAD"] := Map("id", o["DOUBLE"] + 8, "infoType", "DOUBLE", "dllType", "Double*")
        c["SIZE_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 8, "infoType", "OFF_T", "dllType", "Int*")
        c["SPEED_DOWNLOAD"] := Map("id", o["DOUBLE"] + 9, "infoType", "DOUBLE", "dllType", "Double*")
        c["SPEED_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 9, "infoType", "OFF_T", "dllType", "Int*")
        c["SPEED_UPLOAD"] := Map("id", o["DOUBLE"] + 10, "infoType", "DOUBLE", "dllType", "Double*")
        c["SPEED_UPLOAD_T"] := Map("id", o["OFF_T"] + 10, "infoType", "OFF_T", "dllType", "Int*")
        c["HEADER_SIZE"] := Map("id", o["LONG"] + 11, "infoType", "LONG", "dllType", "Int*")
        c["REQUEST_SIZE"] := Map("id", o["LONG"] + 12, "infoType", "LONG", "dllType", "Int*")
        c["SSL_VERIFYRESULT"] := Map("id", o["LONG"] + 13, "infoType", "LONG", "dllType", "Int*")
        c["FILETIME"] := Map("id", o["LONG"] + 14, "infoType", "LONG", "dllType", "Int*")
        c["FILETIME_T"] := Map("id", o["OFF_T"] + 14, "infoType", "OFF_T", "dllType", "Int*")
        c["CONTENT_LENGTH_DOWNLOAD"] := Map("id", o["DOUBLE"] + 15, "infoType", "DOUBLE", "dllType", "Double*")
        c["CONTENT_LENGTH_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 15, "infoType", "OFF_T", "dllType", "Int*")
        c["CONTENT_LENGTH_UPLOAD"] := Map("id", o["DOUBLE"] + 16, "infoType", "DOUBLE", "dllType", "Double*")
        c["CONTENT_LENGTH_UPLOAD_T"] := Map("id", o["OFF_T"] + 16, "infoType", "OFF_T", "dllType", "Int*")
        c["STARTTRANSFER_TIME"] := Map("id", o["DOUBLE"] + 17, "infoType", "DOUBLE", "dllType", "Double*")
        c["CONTENT_TYPE"] := Map("id", o["STRING"] + 18, "infoType", "STRING", "dllType", "Ptr*")
        c["REDIRECT_TIME"] := Map("id", o["DOUBLE"] + 19, "infoType", "DOUBLE", "dllType", "Double*")
        c["REDIRECT_COUNT"] := Map("id", o["LONG"] + 20, "infoType", "LONG", "dllType", "Int*")
        c["PRIVATE"] := Map("id", o["STRING"] + 21, "infoType", "STRING", "dllType", "Ptr*")
        c["HTTP_CONNECTCODE"] := Map("id", o["LONG"] + 22, "infoType", "LONG", "dllType", "Int*")
        c["HTTPAUTH_AVAIL"] := Map("id", o["LONG"] + 23, "infoType", "LONG", "dllType", "Int*")
        c["PROXYAUTH_AVAIL"] := Map("id", o["LONG"] + 24, "infoType", "LONG", "dllType", "Int*")
        c["OS_ERRNO"] := Map("id", o["LONG"] + 25, "infoType", "LONG", "dllType", "Int*")
        c["NUM_CONNECTS"] := Map("id", o["LONG"] + 26, "infoType", "LONG", "dllType", "Int*")
        c["SSL_ENGINES"] := Map("id", o["SLIST"] + 27, "infoType", "SLIST", "dllType", "Ptr")
        c["COOKIELIST"] := Map("id", o["SLIST"] + 28, "infoType", "SLIST", "dllType", "Ptr")
        c["LASTSOCKET"] := Map("id", o["LONG"] + 29, "infoType", "LONG", "dllType", "Int*")
        c["FTP_ENTRY_PATH"] := Map("id", o["STRING"] + 30, "infoType", "STRING", "dllType", "Ptr*")
        c["REDIRECT_URL"] := Map("id", o["STRING"] + 31, "infoType", "STRING", "dllType", "Ptr*")
        c["PRIMARY_IP"] := Map("id", o["STRING"] + 32, "infoType", "STRING", "dllType", "Ptr*")
        c["APPCONNECT_TIME"] := Map("id", o["DOUBLE"] + 33, "infoType", "DOUBLE", "dllType", "Double*")
        c["CERTINFO"] := Map("id", o["PTR"] + 34, "infoType", "PTR", "dllType", "Ptr")
        c["CONDITION_UNMET"] := Map("id", o["LONG"] + 35, "infoType", "LONG", "dllType", "Int*")
        c["RTSP_SESSION_ID"] := Map("id", o["STRING"] + 36, "infoType", "STRING", "dllType", "Ptr*")
        c["RTSP_CLIENT_CSEQ"] := Map("id", o["LONG"] + 37, "infoType", "LONG", "dllType", "Int*")
        c["RTSP_SERVER_CSEQ"] := Map("id", o["LONG"] + 38, "infoType", "LONG", "dllType", "Int*")
        c["RTSP_CSEQ_RECV"] := Map("id", o["LONG"] + 39, "infoType", "LONG", "dllType", "Int*")
        c["PRIMARY_PORT"] := Map("id", o["LONG"] + 40, "infoType", "LONG", "dllType", "Int*")
        c["LOCAL_IP"] := Map("id", o["STRING"] + 41, "infoType", "STRING", "dllType", "Ptr*")
        c["LOCAL_PORT"] := Map("id", o["LONG"] + 42, "infoType", "LONG", "dllType", "Int*")
        c["TLS_SESSION"] := Map("id", o["PTR"] + 43, "infoType", "PTR", "dllType", "Ptr")
        c["ACTIVESOCKET"] := Map("id", o["SOCKET"] + 44, "infoType", "SOCKET", "dllType", "Ptr")
        c["TLS_SSL_PTR"] := Map("id", o["PTR"] + 45, "infoType", "PTR", "dllType", "Ptr")
        c["HTTP_VERSION"] := Map("id", o["LONG"] + 46, "infoType", "LONG", "dllType", "Int*")
        c["PROXY_SSL_VERIFYRESULT"] := Map("id", o["LONG"] + 47, "infoType", "LONG", "dllType", "Int*")
        c["PROTOCOL"] := Map("id", o["LONG"] + 48, "infoType", "LONG", "dllType", "Int*")
        c["SCHEME"] := Map("id", o["STRING"] + 49, "infoType", "STRING", "dllType", "Ptr*")
        c["TOTAL_TIME_T"] := Map("id", o["OFF_T"] + 50, "infoType", "OFF_T", "dllType", "Int*")
        c["NAMELOOKUP_TIME_T"] := Map("id", o["OFF_T"] + 51, "infoType", "OFF_T", "dllType", "Int*")
        c["CONNECT_TIME_T"] := Map("id", o["OFF_T"] + 52, "infoType", "OFF_T", "dllType", "Int*")
        c["PRETRANSFER_TIME_T"] := Map("id", o["OFF_T"] + 53, "infoType", "OFF_T", "dllType", "Int*")
        c["STARTTRANSFER_TIME_T"] := Map("id", o["OFF_T"] + 54, "infoType", "OFF_T", "dllType", "Int*")
        c["REDIRECT_TIME_T"] := Map("id", o["OFF_T"] + 55, "infoType", "OFF_T", "dllType", "Int*")
        c["APPCONNECT_TIME_T"] := Map("id", o["OFF_T"] + 56, "infoType", "OFF_T", "dllType", "Int*")
        c["RETRY_AFTER"] := Map("id", o["OFF_T"] + 57, "infoType", "OFF_T", "dllType", "Int64")
        c["EFFECTIVE_METHOD"] := Map("id", o["STRING"] + 58, "infoType", "STRING", "dllType", "Ptr*")
        c["PROXY_ERROR"] := Map("id", o["LONG"] + 59, "infoType", "LONG", "dllType", "Int*")
        c["REFERER"] := Map("id", o["STRING"] + 60, "infoType", "STRING", "dllType", "Ptr*")
        c["CAINFO"] := Map("id", o["STRING"] + 61, "infoType", "STRING", "dllType", "Ptr*")
        c["CAPATH"] := Map("id", o["STRING"] + 62, "infoType", "STRING", "dllType", "Ptr*")
        c["XFER_ID"] := Map("id", o["OFF_T"] + 63, "infoType", "OFF_T", "dllType", "Int64")
        c["CONN_ID"] := Map("id", o["OFF_T"] + 64, "infoType", "OFF_T", "dllType", "Int64")
        c["QUEUE_TIME_T"] := Map("id", o["OFF_T"] + 65, "infoType", "OFF_T", "dllType", "Int64")
        c["LASTONE"] := Map("id", 65, "infoType", "INVALID", "dllType", "None")
    */
            bindOffsets(offsetGroup,offsetOrdinal,offsetType){
            ret := this._DeepClone(this.constants[offsetGroup][offsetType])
            ret["id"] := ret["offset"] + offsetOrdinal
            ret.delete("offset")
            return ret
        }
        ; bindOffsets(v,o,g,type){
        ;     switch g {
        ;         case "CURLINFO": 
        ;             switch type {
        ;                 case "STRING":
        ;                     return Map(id,o[type]+v,"infoType",type,"dllType","Ptr*")
        ;                 case "LONG":
        ;                 case "DOUBLE":
        ;                 case "SLIST":
        ;                 case "PTR":
        ;                 case "SOCKET":
        ;                 case "OFF_T":
        ;                 case "MASK":
        ;                 case "TYPEMASK":
                                                
        ;             }
        ;     }
        ; }
        ; this.constants["CURLINFO"] := c := Map()
        ; c.CaseSense := 0
        ; c["NONE"] :=  
    
        ; c["EFFECTIVE_URL"] := o["STRING"] + 1
        
        ; c["EFFECTIVE_URL"] := Map("id",o["STRING"] + 1,"infoType","STRING","dllType","Ptr*")
        ; c["RESPONSE_CODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 2
        ; c["TOTAL_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 3
        ; c["NAMELOOKUP_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 4
        ; c["CONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 5
        ; c["PRETRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 6
        ; c["SIZE_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 7
        ; c["SIZE_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 8
        ; c["SPEED_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 9
        ; c["SPEED_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 10
        ; c["HEADER_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 11
        ; c["REQUEST_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 12
        ; c["SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 13
        ; c["FILETIME"] := this.constants["CURLINFO_offsets"]["LONG"] + 14
        ; c["FILETIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 14
        ; c["CONTENT_LENGTH_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 15
        ; c["CONTENT_LENGTH_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 16
        ; c["STARTTRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 17
        ; c["CONTENT_TYPE"] := this.constants["CURLINFO_offsets"]["STRING"] + 18
        ; c["REDIRECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 19
        ; c["REDIRECT_COUNT"] := this.constants["CURLINFO_offsets"]["LONG"] + 20
        ; c["PRIVATE"] := this.constants["CURLINFO_offsets"]["STRING"] + 21
        ; c["HTTP_CONNECTCODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 22
        ; c["HTTPAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 23
        ; c["PROXYAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 24
        ; c["OS_ERRNO"] := this.constants["CURLINFO_offsets"]["LONG"] + 25
        ; c["NUM_CONNECTS"] := this.constants["CURLINFO_offsets"]["LONG"] + 26
        ; c["SSL_ENGINES"] := this.constants["CURLINFO_offsets"]["SLIST"] + 27
        ; c["COOKIELIST"] := this.constants["CURLINFO_offsets"]["SLIST"] + 28
        ; c["FTP_ENTRY_PATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 30
        ; c["REDIRECT_URL"] := this.constants["CURLINFO_offsets"]["STRING"] + 31
        ; c["PRIMARY_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 32
        ; c["APPCONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 33
        ; c["CERTINFO"] := this.constants["CURLINFO_offsets"]["PTR"] + 34
        ; c["CONDITION_UNMET"] := this.constants["CURLINFO_offsets"]["LONG"] + 35
        ; c["RTSP_SESSION_ID"] := this.constants["CURLINFO_offsets"]["STRING"] + 36
        ; c["RTSP_CLIENT_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 37
        ; c["RTSP_SERVER_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 38
        ; c["RTSP_CSEQ_RECV"] := this.constants["CURLINFO_offsets"]["LONG"] + 39
        ; c["PRIMARY_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 40
        ; c["LOCAL_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 41
        ; c["LOCAL_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 42
        ; c["ACTIVESOCKET"] := this.constants["CURLINFO_offsets"]["SOCKET"] + 44
        ; c["TLS_SSL_PTR"] := this.constants["CURLINFO_offsets"]["PTR"] + 45
        ; c["HTTP_VERSION"] := this.constants["CURLINFO_offsets"]["LONG"] + 46
        ; c["PROXY_SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 47
        ; c["SCHEME"] := this.constants["CURLINFO_offsets"]["STRING"] + 49
        ; c["TOTAL_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 50
        ; c["NAMELOOKUP_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 51
        ; c["CONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 52
        ; c["PRETRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 53
        ; c["STARTTRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 54
        ; c["REDIRECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 55
        ; c["APPCONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 56
        ; c["RETRY_AFTER"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 57
        ; c["EFFECTIVE_METHOD"] := this.constants["CURLINFO_offsets"]["STRING"] + 58
        ; c["PROXY_ERROR"] := this.constants["CURLINFO_offsets"]["LONG"] + 59
        ; c["REFERER"] := this.constants["CURLINFO_offsets"]["STRING"] + 60
        ; c["CAINFO"] := this.constants["CURLINFO_offsets"]["STRING"] + 61
        ; c["CAPATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 62
        ; c["XFER_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 63
        ; c["CONN_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 64
        ; c["QUEUE_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 65
        ; c["LASTONE"] := 65
    }

    _curl_easy_cleanup(easy_handle) {    ;https://curl.se/libcurl/c/curl_easy_cleanup.html
        DllCall(this.curlDLLpath "\curl_easy_cleanup"
            ,   "Ptr", easy_handle)
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
    _curl_easy_getinfo(easy_handle,info,&retCode) {  ;untested   https://curl.se/libcurl/c/curl_easy_getinfo.html
        static c := this.constants["CURLINFO"]
    
        ; MsgBox info "`n" c[info]["dllType"]
        ; c[info]["dllType"] := "Str"
        ; c[info]["dllType"] := "Str*"
        ; c[info]["dllType"] := "Ptr"
        ; c[info]["dllType"] := "Ptr*"
        check := DllCall(this.curlDLLpath "\curl_easy_getinfo"
            ,   "Ptr", easy_handle
            ; ,   "Int", requestedInfo
            ,   "Int", c[info]["id"]
            ,   c[info]["dllType"], &retCode)
            ; ,   "Int*", &retCode)
        ; msgbox check "`n" StrGet(retCode,"UTF-8")
    
        ;     ExitApp
            return
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

}