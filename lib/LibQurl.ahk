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


    /*
        ;orig
        HeaderToMem(maxCapacity := 0, handle?) {
            handle ??= this.handleMap[0]["handle"]   ;defaults to the last created handle
            passedHandleMap := this.handleMap
            this.handleMap[handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "header", handle)
            this.SetOpt("HEADERDATA",this.handleMap[handle]["callbacks"]["header"]["storageHandle"],handle)
            this.SetOpt("HEADERFUNCTION",this.handleMap[handle]["callbacks"]["header"]["CBF"],handle)
            Return
        }
    */






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
        retCode := DllCall("libcurl-x64\curl_easy_perform","Ptr",easy_handle)
        ; msgbox "perform code: " retCode
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
        easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle
    
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

    _curl_easy_init() {
        return DllCall(this.curlDLLpath "\curl_easy_init"
            ,   "Ptr")
    }
    
    _curl_easy_option_next(optPtr) {    ;https://curl.se/libcurl/c/curl_easy_option_next.html
        return DllCall("libcurl-x64\curl_easy_option_next"
            ,   "UInt", optPtr
            ,   "Ptr")
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

}