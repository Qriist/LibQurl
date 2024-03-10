class LibQurl {
    __New() {
        this.handleMap := Map()
        static curlDLLhandle := ""
        static curlDLLpath := ""
        this.Opt := Map()   ;option reference matrix
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
        ; msgbox this["CurlVersionInfo"]
        this["Version Info"] := this.GetVersionInfo()
        return this.Init()
    }
    GetVersionInfo(){
        verPtr := this._curl_version_info()
        retObj := this.struct.curl_version_info_data(verPtr)
        return retObj
    }

    ListHandles(){
        ;returns a plaintext listing of all handles
        ret := ""
        for k,v in this.handleMap {
            ret .= k "`n"
        }
        return Trim(ret,"`n")
    }
    Init(){
        handle := this._curl_easy_init()
        this.handleMap[handle] := this.handleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created handle
        If !this.handleMap[handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)
        this.handleMap[handle]["handle"] := handle
        this.handleMap[handle]["options"] := Map()  ;prepares option storage
        ,this.SetOpt("ACCEPT_ENCODING","",handle)    ;enables compressed transfers without affecting input headers
        ,this.SetOpt("FOLLOWLOCATION",1,handle)    ;allows curl to follow redirects
        ,this.SetOpt("MAXREDIRS",30,handle)    ;limits redirects to 30 (matches recent curl default)
        
        ;try to auto-load curl's cert bundle
        ;can still be set per handle
        SplitPath(this.curlDLLpath,,&dlldir)
        If FileExist(dlldir "\curl-ca-bundle.crt")
            this.SetOpt("CAINFO",dlldir "\curl-ca-bundle.crt",handle)

        this.handleMap[handle]["callbacks"] := Map()  ;prepares write callbacks
        for k,v in ["body","header","read","progress","debug"]{
            this.handleMap[handle]["callbacks"][v] := Map()
            this.handleMap[handle]["callbacks"][v]["CBF"] := ""
        }
        this._setCallbacks(1,1,1,1,,handle) ;don't enable debug by default
        this.HeaderToMem(0,handle)    ;automatically save lastHeader to memory
        return handle
    }
    EasyInit(){ ;just a clarifying alias for Init()
        return this.Init()
    }
    ; DupeInit(handle?){
        ; newHandle := this._curl_easy_duphandle(handle)
        ; this.handleMap[newHandle] := this.handleMap[0] := this.DeepClone(this.handleMap[handle])
        ; If !this.handleMap[newHandle]
        ;     throw ValueError("Problem in 'curl_easy_duphandle'! Unable to init easy interface!", -1, this.curlDLLpath)
        ; this.handleMap[newHandle] := this.handleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created handle
        ; ,this.handleMap[newHandle]["options"] := Map()  ;prepares option storage
        ; for k,v in this.handleMap[handle]["options"]
        ;     this.SetOpt(k,v,newHandle)
        ; this.handleMap[newHandle]["handle"] := newHandle
        ; return newHandle 
        /*
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        newHandle := this._curl_easy_duphandle(handle)
        If !this.handleMap[handle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)
        ; msgbox handle "`n" newHandle "`n`n" this.handleMap[0]["handle"]
        this.handleMap[newHandle] := this.DeepClone(this.handleMap[handle])
        msgbox this.ShowOB(this.handleMap[newHandle])
        this.handleMap[0]["handle"] := this.handleMap[newHandle]["handle"]
        ; msgbox this.handleMap[newHandle]["handle"] "`n" this.handleMap[handle]["handle"] "`n`n" this.handleMap[0]["handle"]
        ; this.handleMap[newHandle] := this.handleMap[0] := Map() ;handleMap[0] is a dynamic reference to the last created handle
        ; ,this.handleMap[newHandle]["options"] := Map()  ;prepares option storage


        ; for k,v in this.handleMap[handle]["options"]
        ;     this.SetOpt(k,v,newHandle)
        return newHandle   
        */     
    ; }
    GetErrorString(errornum){
        return StrGet(this._curl_easy_strerror(errornum),"UTF-8")
    }
    ListOpts(handle?){  ;returns human-readable printout of the given handle's set options
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        ret := "These are the options that have been set for this handle:`n"
        for k,v in this.handleMap[handle]["options"]{
                if (v!="")
                    ret .= k ": " (!IsObject(v)?v:"<OBJECT>") "`n"
                else
                    ret .= k ": " "<NULL>" "`n"
        }
        return ret
    }

    ShowOB(ob, strOB := "") {  ; returns `n list.  pass object, returns list of elements. nice chart format with `n.  strOB for internal use only.
        (Type(Ob) ~= 'Object|Gui') ? Ob := Ob.OwnProps() : 1
        for i, v in ob
        (!isobject(v)) ? (rets .= "`n [" strOB i "] = [" v "]") : (rets .= ShowOB(v, strOB i "."))
        return isSet(rets) ? rets : ""
    }
    SetOpt(option,parameter,handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        this.handleMap[handle]["options"][option] := parameter
        return this._curl_easy_setopt(handle,option,parameter)
    }

    WriteToFile(filename, handle?) {
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        ;instanstiate Storage.File
        passedHandleMap := this.handleMap
        this.handleMap[handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "body", "w", handle)
        this.SetOpt("WRITEDATA",this.handleMap[handle]["callbacks"]["body"]["storageHandle"],handle)
        this.SetOpt("WRITEFUNCTION",this.handleMap[handle]["callbacks"]["body"]["CBF"],handle) 
        Return
    }

    WriteToMem(maxCapacity := 0, handle?) {
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        passedHandleMap := this.handleMap
        this.handleMap[handle]["callbacks"]["body"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "body", handle)
        this.SetOpt("WRITEDATA",this.handleMap[handle]["callbacks"]["body"]["storageHandle"],handle)
        this.SetOpt("WRITEFUNCTION",this.handleMap[handle]["callbacks"]["body"]["CBF"],handle)
		Return
	}
	
	; WriteToNone() {
	; 	Return (this._writeTo := "")
	; }

    ; WriteToMagic(handle?) {
    ;     if !IsSet(handle)
    ;         handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
    ;     ;instanstiate Storage.File
    ;     passedHandleMap := this.handleMap
    ;     this.handleMap[handle]["callbacks"]["body"]["storageHandle"] := class_libcurl.Storage.File(filename, &passedHandleMap, "body", "w", handle)
    ;     this.SetOpt("WRITEDATA",this.handleMap[handle]["callbacks"]["body"]["storageHandle"],handle)
    ;     this.SetOpt("WRITEFUNCTION",this.handleMap[handle]["callbacks"]["body"]["CBF"],handle) 
    ;     Return
    ; }
	
	HeaderToFile(filename, handle?) {
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        passedHandleMap := this.handleMap
        this.handleMap[handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.File(filename, &passedHandleMap, "header", "w", handle)
        this.SetOpt("HEADERDATA",this.handleMap[handle]["callbacks"]["header"]["storageHandle"],handle)
        this.SetOpt("HEADERFUNCTION",this.handleMap[handle]["callbacks"]["header"]["CBF"],handle)
		Return
	}
	
	HeaderToMem(maxCapacity := 0, handle?) {
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        passedHandleMap := this.handleMap
		this.handleMap[handle]["callbacks"]["header"]["storageHandle"] := LibQurl.Storage.MemBuffer(dataPtr?, maxCapacity?, dataSize?, &passedHandleMap, "header", handle)
        this.SetOpt("HEADERDATA",this.handleMap[handle]["callbacks"]["header"]["storageHandle"],handle)
        this.SetOpt("HEADERFUNCTION",this.handleMap[handle]["callbacks"]["header"]["CBF"],handle)
        Return
	}
	
	; HeaderToNone() {
	; 	Return (this._headerTo := "")
	; }


    _setCallbacks(body?,header?,read?,progress?,debug?,handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle

        if IsSet(body){
            CBF := this.handleMap[handle]["callbacks"]["body"]["CBF"]
            if IsInteger(CBF){  ;checks if this callback already exists
                this.writeRefs[CBF] -= 1    ;decrement the reference tracker
                ,CallbackFree(CBF)
                ,(CBF=0?writeRefs.delete(CBF):"")   ;remove key if done with it
            }

            this.handleMap[handle]["callbacks"]["body"]["CBF"] := CBF := CallbackCreate(
                (dataPtr, size, sizeBytes, userdata) =>
                this._writeCallbackFunction(dataPtr, size, sizeBytes, userdata, handle)
            )

            ;creates the tracking key
            this.writeRefs[CBF] := 1
        }


        if IsSet(header){
            CBF := this.handleMap[handle]["callbacks"]["header"]["CBF"]
            if IsInteger(CBF){  ;checks if this callback already exists
                this.writeRefs[CBF] -= 1    ;decrement the reference tracker
                ,CallbackFree(CBF)
                ,(CBF=0?writeRefs.delete(CBF):"")   ;remove key if done with it
            }
            ; if IsInteger(this.handleMap[handle]["callbacks"]["header"]["CBF"])
            ;     CallbackFree(this.handleMap[handle]["callbacks"]["header"]["CBF"])
            this.handleMap[handle]["callbacks"]["header"]["CBF"] := CBF := CallbackCreate(
                (dataPtr, size, sizeBytes, userdata) =>
                this._headerCallbackFunction(dataPtr, size, sizeBytes, userdata, handle)
            )
            
            ;creates the tracking key
            this.writeRefs[CBF] := 1
            ; msgbox (CBF)
        }
        ; if IsSet(read)
        ; if IsSet(progress)
        ; if IsSet(debug)
        
        
        ;non-lambda rewrite
        ;   actualCallbackFunction(dataPtr, size, sizeBytes, userdata) {
        ;     return this._writeCallbackFunction(dataPtr, size, sizeBytes, userdata, passed_curl_handle)
        ;   }
        ;   this.handleMap[handle]["writeCallbackFunction"] := CallbackCreate(actualCallbackFunction)
        ; Curl._CB_Header   := CallbackCreate(Curl._HeaderCallback)
		; Curl._CB_Read     := CallbackCreate(Curl._ReadCallback)
		; Curl._CB_Progress := CallbackCreate(Curl._ProgressCallback)
		; Curl._CB_Debug    := CallbackCreate(Curl._DebugCallback)
    }
    Perform(handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        this.handleMap[handle]["callbacks"]["body"]["storageHandle"].Open()
        this.handleMap[handle]["callbacks"]["header"]["storageHandle"].Open()
        retCode := DllCall("libcurl-x64\curl_easy_perform","Ptr",handle)
        ; msgbox "perform code: " retCode
        this.handleMap[handle]["callbacks"]["body"]["storageHandle"].Close()
        this.handleMap[handle]["callbacks"]["header"]["storageHandle"].Close()

        ;accessibly attach body to handle output
        bodyObj := this.handleMap[handle]["callbacks"]["body"]
        lastBody := (bodyObj["writeType"]="memory"?bodyObj["writeTo"]:FileOpen(bodyObj["filename"],"r").Read())
        this.handleMap[handle]["lastBody"] := lastBody

        ;accessibly attach headers to handle output
        headerObj := this.handleMap[handle]["callbacks"]["header"]
        lastHeaders := (headerObj["writeType"]="memory"?StrGet(headerObj["writeTo"],"UTF-8"):FileOpen(headerObj["filename"],"r").Read())
        this.handleMap[handle]["lastHeaders"] := lastHeaders
        return retCode
    }
    GetLastHeaders(handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        return this.handleMap[handle]["lastHeaders"]
    }
    GetLastBody(returnAsEncoding := "UTF-8",handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        if (returnAsEncoding = "Buffer")
            return this.handleMap[handle]["lastBody"]
        return StrGet(this.handleMap[handle]["lastBody"],,returnAsEncoding)
    }
    Cleanup(handle?){
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        for k,v in this.handleMap[handle]["callbacks"]
            if IsInteger(this.handleMap[handle]["callbacks"][k]["CBF"])
                CallbackFree(this.handleMap[handle]["callbacks"][k]["CBF"])
        this.handleMap.Delete(handle)
        this._curl_easy_cleanup(handle)
    }
    EasyCleanup(handle?){   ;alias for Cleanup
        this.Cleanup(handle?)
    }
	; Callbacks
	; =========
    _writeCallbackFunction(dataPtr, size, sizeBytes, userdata, handle) {
		dataSize := size * sizeBytes
        return this.handleMap[handle]["callbacks"]["body"]["storageHandle"].RawWrite(dataPtr, dataSize)
	}

	_headerCallbackFunction(dataPtr, size, sizeBytes, userdata, handle) {
		dataSize := size * sizeBytes
        ; msgbox type(this.handleMap[handle]["callbacks"]["header"]["storageHandle"])
		Return this.handleMap[handle]["callbacks"]["header"]["storageHandle"].RawWrite(dataPtr, dataSize)
	}
 
    Class Storage {
        ; Wrapper for file. Shouldn't be used directly.
        Class File {
            __New(filename, &handleMap, storageCategory, accessMode := "w", handle?) {
                this.handleMap := handleMap
                if !IsSet(handle)
                    handle := this.handleMap[0]["handle"]   ;defaults to the last created handle

                this.writeObj := this.handleMap[handle]["callbacks"][storageCategory]
                this.writeObj["writeType"] := "file"
                this.writeObj["filename"] := filename
                this.writeObj["accessMode"] := accessMode
                this.writeObj["writeTo"] := ""
                this.writeObj["curlHandle"] := handle
                this.storageCategory := storageCategory
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
                    
                    ;associates the write object with the curl handle
                    ; this.handleMap["assoc"][this.writeObj["writeTo"].handle] := this.getCurlHandle()
                    ; msgbox this.handleMap["assoc"][this.getHandle()]
                }
            }

            Close() {
            	this.writeObj["writeTo"].Close()
                ; this.handleMap["assoc"].Delete(this.writeObj["writeTo"].handle)
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
        	__New(dataPtr := 0, maxCapacity?, dataSize := 0, &handleMap?, storageCategory?, handle?) {
        		; this._data     := ""
        		this._dataPos  := 0
                this.handleMap := handleMap
                if !IsSet(handle)
                    handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
                this.handle := handle
                this.storageCategory := storageCategory
                this.writeObj := this.handleMap[handle]["callbacks"][storageCategory]
                this.writeObj["writeType"] := "memory"

                If !IsSet(maxCapacity)
        			maxCapacity := 8*1024*1024  ; 8 Mb
                this.writeObj["maxCapacity"] := maxCapacity
                this.writeObj["writeTo"] := Buffer(maxCapacity := Max(maxCapacity, dataSize))
                ; this.writeObj["writeTo"] := Buffer(maxCapacity)
                this.writeObj["curlHandle"] := handle
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
        			this._dataPtr  := "" ;ObjGetAddress(this._data)
        		}
        	}

        	Open() {
        		; Do nothing
        	}

        	Close() {
        		; this.handleMap[this.handle]["lastHeaders"] := this.writeObj["writeTo"]
                ; msgbox strget(this.writeObj["writeBuffer"],"UTF-8")
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
                Offset := this.writeObj["writeTo"].Size
                this.writeObj["writeTo"].Size += srcDataSize
                DllCall("ntdll\memcpy"
                    , "Ptr" , this.writeObj["writeTo"].Ptr + Offset
                    , "Ptr" , srcDataPtr+0
                    , "Int" , srcDataSize)
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
	SetHeaders(headersArrayOrMap,handle?) {
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
		Return this.SetOpt("HTTPHEADER", headersPtr,handle?)
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
    _curl_easy_cleanup(handle) {

    }
    _curl_easy_duphandle(handle) {
        ret := DllCall(this.curlDLLpath "\curl_easy_duphandle"
            , "Int", handle)
        return ret
    }
    _curl_easy_escape(handle, url) {
        ;doesn't like unicode, should I use the native windows function for this?
        ;char *curl_easy_escape(CURL *curl, const char *string, int length);
        esc := DllCall(this.curlDLLpath "\curl_easy_escape"
            , "Ptr", handle
            , "AStr", url
            , "Int", 0
            , "Ptr")
        return StrGet(esc, "UTF-8")

    }
    _curl_easy_getinfo() {

    }
    _curl_easy_header() {

    }
    _curl_easy_init() {
        return DllCall(this.curlDLLpath "\curl_easy_init")
    }
    _curl_easy_nextheader() {

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
    _curl_easy_option_next(optPtr) {
        return DllCall("libcurl-x64\curl_easy_option_next", "UInt", optPtr, "Ptr")
    }
    _curl_easy_pause() {

    }
    _curl_easy_perform(handle?) {
        if !IsSet(handle)
            handle := this.handleMap[0]["handle"]   ;defaults to the last created handle
        retCode := DllCall(this.curlDLLpath "\curl_easy_perform"
            , "Ptr", handle)
        return retCode
    }
    _curl_easy_recv() {

    }
    _curl_easy_reset(handle) {
        DllCall(this.curlDLLpath "\curl_easy_reset"
            , "Ptr", handle)
    }
    _curl_easy_send() {

    }
    _curl_easy_setopt(handle, option, parameter, debug?) {
        if IsSet(debug)
            msgbox this.showob(this.opt[option]) "`n`n`n"
        ; .   "passed handle: " handle "`n"
        ; .   "passed id:" this.opt[option].id "`n"
        ; .   "passed type: " argTypes[this.opt[option].type]
        retCode := DllCall(this.curlDLLpath "\curl_easy_setopt"
            , "Ptr", handle
            , "Int", this.opt[option]["id"]
            , this.opt[option]["type"], parameter)
        return retCode
    }
    _curl_easy_strerror(errornum) {
        return DllCall(this.curlDLLpath "\curl_easy_strerror"
            , "Int", errornum
            ,"Ptr")
    }
    _curl_easy_unescape() {

    }
    _curl_easy_upkeep() {

    }
    _curl_formadd() {

    }
    _curl_formfree() {

    }
    _curl_formget() {

    }
    _curl_free() {

    }
    _curl_getdate() {

    }
    _curl_global_cleanup(handle) {
        DllCall(this.curlDLLpath "\curl_global_cleanup")
    }
    _curl_global_init() {   ;https://curl.se/libcurl/c/curl_global_init.html
        ;can't find the various flag values so it's locked to the default "everything" mode for now - prolly okay
        if DllCall(this.curlDLLpath "\curl_global_init", "Int", 0x03, "CDecl")  ;returns 0 on success
            throw ValueError("Problem in 'curl_global_init'! Unable to init DLL!", -1, this.curlDLLpath)
        else
            return
    }
    _curl_global_init_mem() {

    }
    _curl_global_sslset() {

    }
    _curl_mime_addpart() {

    }
    _curl_mime_data() {

    }
    _curl_mime_data_cb() {

    }
    _curl_mime_encoder() {

    }
    _curl_mime_filedata() {

    }
    _curl_mime_filename() {

    }
    _curl_mime_free() {

    }
    _curl_mime_headers() {

    }
    _curl_mime_init() {

    }
    _curl_mime_name() {

    }
    _curl_mime_subparts() {

    }
    _curl_mime_type() {

    }
    _curl_multi_add_handle() {

    }
    _curl_multi_assign() {

    }
    _curl_multi_cleanup() {

    }
    _curl_multi_fdset() {

    }
    _curl_multi_info_read() {

    }
    _curl_multi_init() {

    }
    _curl_multi_perform() {

    }
    _curl_multi_remove_handle() {

    }
    _curl_multi_setopt() {

    }
    _curl_multi_socket_action() {

    }
    _curl_multi_strerror() {

    }
    _curl_multi_timeout() {

    }
    _curl_multi_poll() {

    }
    _curl_multi_wait() {

    }
    _curl_multi_wakeup() {

    }
    _curl_pushheader_byname() {

    }
    _curl_pushheader_bynum() {

    }
    _curl_share_cleanup() {

    }
    _curl_share_init() {

    }
    _curl_share_setopt() {

    }
    _curl_share_strerror() {

    }
    _curl_slist_append(ptrSList,strArrayItem) { ;https://curl.se/libcurl/c/curl_slist_append.html
        return DllCall(this.curlDLLpath "\curl_slist_append"
            , "Ptr" , ptrSList
            , "AStr", strArrayItem
            , "Ptr")
    }
    _curl_slist_free_all(ptrSList) {
        return DllCall(Curl.curlDLLpath . "\curl_slist_free_all"
            , "Ptr", ptrSList)
    }
    _curl_url() {

    }
    _curl_url_cleanup() {

    }
    _curl_url_dup() {

    }
    _curl_url_get() {

    }
    _curl_url_set() {

    }
    _curl_url_strerror() {

    }
    _curl_version() {   ;https://curl.se/libcurl/c/curl_version.html
        return StrGet(DllCall(this.curlDLLpath "\curl_version", "char", 0, "ptr"), "UTF-8")
    }
    _curl_version_info() {  ;https://curl.se/libcurl/c/curl_version_info.html
        ;returns run-time libcurl version info
        
        verPtr := DllCall(this.curlDLLpath "\curl_version_info", "Int", 0xA, "Ptr")



        return verPtr
    }
    _curl_ws_recv() {

    }
    _curl_ws_send() {

    }
    _curl_ws_meta() {

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
            retObj["age"] := NumGet(ptr,(Offset := 0),"Int") +1 
            retObj["version"] := StrGet(NumGet(ptr,8,"UPtr"),"UTF-8")
            retObj["version_num"] := NumGet(ptr,16,"UInt")
            retObj["host"] := StrGet(NumGet(ptr,24,"UPtr"),"UTF-8")
            retObj["features"] := NumGet(ptr,32,"UInt")
            retObj["ssl_version"] := StrGet(NumGet(ptr,40,"UPtr"),"UTF-8")
            retObj["ssl_version_num"] := NumGet(ptr,48,"UInt")
            retObj["libz_version"] := StrGet(NumGet(ptr,56,"UPtr"),"UTF-8")
            retObj["protocols"] := this.walkPtrArray(NumGet(ptr,64,"UPtr"))

            ;walk through optional struct members
            If (retObj["age"] >= 2) {
                retObj["ares"] := (NumGet(ptr,72,"Ptr")=0?0:StrGet(NumGet(ptr,72,"Ptr"),"UTF-8"))
                retObj["ares"] := NumGet(ptr,80,"Int")
            }
            If (retObj["age"] >= 3) {
                retObj["libidn"] := (NumGet(ptr,88,"Ptr")=0?0:StrGet(NumGet(ptr,88,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 4) {
                retObj["iconv_ver_num"] := NumGet(ptr, 96, "Int")
                retObj["libssh_version"] := (NumGet(ptr,104,"Ptr")=0?0:StrGet(NumGet(ptr,104,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 5) {
                retObj["brotli_ver_num"] := NumGet(ptr, 112, "Int")
                retObj["brotli_version"] := StrGet(NumGet(ptr + 120, "Ptr"), "UTF-8")
            }
            If (retObj["age"] >= 6) {
                retObj["nghttp2_version"] := NumGet(ptr + 128, "UInt")
                retObj["nghttp2"] := (NumGet(ptr,136,"Ptr")=0?0:StrGet(NumGet(ptr,136,"Ptr"),"UTF-8"))
                retObj["quic_version"] := (NumGet(ptr,144,"Ptr")=0?0:StrGet(NumGet(ptr,144,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 7) {
                retObj["cainfo"] := (NumGet(ptr,152,"Ptr")=0?0:StrGet(NumGet(ptr,152,"Ptr"),"UTF-8"))
                retObj["capath"] := (NumGet(ptr,160,"Ptr")=0?0:StrGet(NumGet(ptr,160,"Ptr"),"UTF-8"))    
            }
            If (retObj["age"] >= 8) {
                retObj["zstd_ver_num"] := NumGet(ptr,168,"Ptr")
                retObj["zstd_version"] := (NumGet(ptr,176,"Ptr")=0?0:StrGet(NumGet(ptr,176,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 9) {
                retObj["hyper_version"] := (NumGet(ptr,184,"Ptr")=0?0:StrGet(NumGet(ptr,184,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 10) {
                retObj["gsasl_version"] := (NumGet(ptr,192,"Ptr")=0?0:StrGet(NumGet(ptr,192,"Ptr"),"UTF-8"))
            }
            If (retObj["age"] >= 11) {
                retObj["feature_names"] := this.walkPtrArray(NumGet(ptr,200,"Ptr"))
            }
            return retObj
        }

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

            ; o.type := argTypes[o.rawCurlType].type
            ;     , o.easyType := argTypes[o.rawCurlType].easyType
            ; this.Opt["CURLOPT_" o.name] := this.Opt[o.name] := this.Opt[o.id] := o
            ; static argTypes := { 0: { type: "Int", easyType: "CURLOT_LONG" }
            ;     , 1: { type: "Int", easyType: "CURLOT_VALUES" }
            ;     , 2: { type: "Int64", easyType: "CURLOT_OFF_T" }
            ;     , 3: { type: "Ptr", easyType: "CURLOT_OBJECT" }
            ;     , 4: { type: "Astr", easyType: "CURLOT_STRING" }
            ;     , 5: { type: "Ptr", easyType: "CURLOT_SLIST" }
            ;     , 6: { type: "Ptr", easyType: "CURLOT_CBPTR" }
            ;     , 7: { type: "Ptr", easyType: "CURLOT_BLOB" }
            ;     , 8: { type: "Ptr", easyType: "CURLOT_FUNCTION" } }
            ; o.type := argTypes[o.rawCurlType].type
            ;     , o.easyType := argTypes[o.rawCurlType].easyType
            ; this.Opt["CURLOPT_" o.name] := this.Opt[o.name] := this.Opt[o.id] := o
            o["type"] := argTypes[o["rawCurlType"]]["type"]
                , o["easyType"] := argTypes[o["rawCurlType"]]["easyType"]
            this.Opt["CURLOPT_" o["name"]] := this.Opt[o["name"]] := this.Opt[o["id"]] := o
        }
        ; msgbox this.ShowOB(this.opt)
    }
}