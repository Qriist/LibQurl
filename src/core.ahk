;This file contains the core features of LibQurl.
;Generally, anything a user might want to directly access should go here.
;leave the #compile:whatever lines at the bottom!
;***
#requires Autohotkey v2.1-alpha.2
class LibQurl {
    ;core functionality
    __New() {
        this.easyHandleMap := Map()
        static curlDLLhandle := ""
        static curlDLLpath := ""
        this.Opt := Map()
        this.OptById := Map()
        this.struct := LibQurl._struct()  ;holds the various structs
        this.writeRefs := Map()    ;holds the various write handles
        this.CURL_ERROR_SIZE := 256
    }
    register(dllPath) {
        if !FileExist(dllPath)
            throw ValueError("libcurl DLL not found!", -1, dllPath)
        this.curlDLLpath := dllpath
        this.curlDLLhandle := DllCall("LoadLibrary", "Str", dllPath, "Ptr")   ;load the DLL into resident memory
        this._curl_global_init()
        this._buildOptMap()
        this.VersionInfo := this.GetVersionInfo()
        return this.Init()
    }
    Init(){
        easy_handle := this._curl_easy_init()
        
        this.easyHandleMap[easy_handle] := this.easyHandleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created easy_handle
        If !this.easyHandleMap[easy_handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)
        this.easyHandleMap[easy_handle]["easy_handle"] := easy_handle
        this.easyHandleMap[easy_handle]["options"] := Map()  ;prepares option storage
        this.SetOpt("ACCEPT_ENCODING","",easy_handle)    ;enables compressed transfers without affecting input headers
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
    SetOpt(option,parameter,easy_handle?,debug?){
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle

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
    GetErrorString(errornum){
        return StrGet(this._curl_easy_strerror(errornum),"UTF-8")
    }
	HeaderToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
		this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "header", easy_handle)
        
        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].ptr
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
        Return
	}


    WriteToMem(maxCapacity := 0, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "header", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("HEADERDATA",writeHandle,easy_handle)
        this.SetOpt("HEADERFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["header"]["CBF"],easy_handle)
		Return
	}

    WriteToFile(filename, easy_handle?) {
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        passedHandleMap := this.easyHandleMap
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "body", "w", easy_handle)

        writeHandle := this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].writeObj["writeTo"].handle
        this.SetOpt("WRITEDATA",writeHandle,easy_handle)
        this.SetOpt("WRITEFUNCTION",this.easyHandleMap[easy_handle]["callbacks"]["body"]["CBF"],easy_handle) 
        Return
    }

    Perform(easy_handle?){
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        this.easyHandleMap[easy_handle]["callbacks"]["body"]["storageHandle"].Open()
        this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].Open()
        retcode := this._curl_easy_perform(easy_handle)
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
        return retCode
    }
    GetLastHeaders(returnAsEncoding := "UTF-8",easy_handle?){
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
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
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
        for k,v in this.easyHandleMap[easy_handle]["callbacks"]
            if IsInteger(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])
                CallbackFree(this.easyHandleMap[easy_handle]["callbacks"][k]["CBF"])
        this.easyHandleMap.Delete(easy_handle)
        this._curl_easy_cleanup(easy_handle)
    }
    EasyCleanup(easy_handle?){   ;alias for Cleanup
        this.Cleanup(easy_handle?)
    }

;#compile:helper
;#compile:_struct
;#compile:storage
;#compile:dll
}