;This file generally contains the little methods that support core functionality.
;Most methods that aren't in a class and aren't called directly by the user should go here.
;***
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
    ; msgbox this.PrintObj(this.opt)
}
_mimePartCleanup(mime_part){
        partMap := this.mimePartMap[mime_part]
        mime_handle := partMap["associated_mime_handle"]
        
        ;discover and clean nested parts
        if partMap.has("associated_mime_parts")
            for k,v in partMap["associated_mime_parts"]
                this._mimePartCleanup(k)
        
        ;stage the callbacks to be freed
        for k,v in partMap["callbacks"]
            this.mimePartCBFcleanupArr.push(v)

        this.mimePartMap.Delete(mime_part)
}

_setCallbacks(body?,header?,read?,progress?,debug?,easy_handle?){
    easy_handle ??= this.easyHandleMap[0][1]   ;defaults to the first created easy_handle

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
    if IsSet(read) {
        CBF := this.easyHandleMap[easy_handle]["callbacks"]["read"]["CBF"]
                if IsInteger(CBF){  ;checks if this callback already exists
            this.writeRefs[CBF] -= 1    ;decrement the reference tracker
            CallbackFree(CBF)
            (CBF=0?this.writeRefs.delete(CBF):"")   ;remove key if done with it
        }

        this.easyHandleMap[easy_handle]["callbacks"]["read"]["CBF"] := CBF := CallbackCreate(
            (buf, size, nitems, userdata) =>
            this._readCallbackFunction(buf, size, nitems, userdata)
        )

        this.SetOpt("READDATA",easy_handle,easy_handle)
        this.SetOpt("READFUNCTION",CBF,easy_handle)
        this.writeRefs[CBF] := 1
    }
    
    if IsSet(progress) {
        this.SetOpt("NOPROGRESS", 0, easy_handle)   ;enables progress meter on this handle
        
        CBF := this.easyHandleMap[easy_handle]["callbacks"]["progress"]["CBF"]
        if IsInteger(CBF){  ;checks if this callback already exists
            this.writeRefs[CBF] -= 1    ;decrement the reference tracker
            CallbackFree(CBF)
            (CBF=0?this.writeRefs.delete(CBF):"")   ;remove key if done with it
        }

        this.easyHandleMap[easy_handle]["callbacks"]["progress"]["CBF"] := CBF := CallbackCreate(
            (easy_handle, expectedBytesDownloaded, currentBytesDownloaded , expectedBytesUploaded, currentBytesUploaded) =>
            this._progressCallbackFunction(easy_handle, expectedBytesDownloaded, currentBytesDownloaded , expectedBytesUploaded, currentBytesUploaded)
        )

        this.SetOpt("XFERINFODATA",easy_handle,easy_handle)
        this.SetOpt("XFERINFOFUNCTION",CBF,easy_handle)
        this.writeRefs[CBF] := 1
    }
    if IsSet(debug){
        this.SetOpt("VERBOSE", 1, easy_handle)    ;enables 

        CBF := this.easyHandleMap[easy_handle]["callbacks"]["debug"]["CBF"]
        if IsInteger(CBF){  ;checks if this callback already exists
            this.writeRefs[CBF] -= 1    ;decrement the reference tracker
            CallbackFree(CBF)
            (CBF=0?this.writeRefs.delete(CBF):"")   ;remove key if done with it
        }

        this.easyHandleMap[easy_handle]["callbacks"]["debug"]["CBF"] := CBF := CallbackCreate(
            (easy_handle, infotype, data , size, clientp) =>
            this._debugCallbackFunction(easy_handle, infotype, data, size, clientp)
        )

        this.SetOpt("DEBUGDATA",easy_handle,easy_handle)
        this.SetOpt("DEBUGFUNCTION",CBF,easy_handle)
        this.writeRefs[CBF] := 1
    }
    
    
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
    Return this.easyHandleMap[easy_handle]["callbacks"]["header"]["storageHandle"].RawWrite(dataPtr, dataSize)
}

_progressCallbackFunction(easy_handle, expectedBytesDownloaded, currentBytesDownloaded , expectedBytesUploaded, currentBytesUploaded){
    progressMap := this.easyHandleMap[easy_handle]["callbacks"]["progress"]
    progressMap["expectedBytesDownloaded"] := expectedBytesDownloaded
    progressMap["currentBytesDownloaded"] := currentBytesDownloaded
    progressMap["expectedBytesUploaded"] := expectedBytesUploaded
    progressMap["currentBytesUploaded"] := currentBytesUploaded
    return 0
}

_readCallbackFunction(toBuf, size, nitems, easy_handle){
    bytes := size * nitems
    fromBuf := Buffer(bytes)
    bytesRead := this.easyHandleMap[easy_handle]["postFile"].RawRead(fromBuf,bytes)
    fromBuf.Size := bytesRead   ;auto-truncates the buffer if needed

    DllCall("RtlMoveMemory"
            ,   "Ptr", toBuf    ;destination
            ,   "Ptr", fromBuf  ;source
            ,   "UPtr", bytesRead)  ;length

    return bytesRead
}

_debugCallbackFunction(easy_handle, infotype, data, size, clientp){
    pushObj := Map("infotype",infotype,"timestamp",this.Timestamp())
    switch infotype {
        case 0,1,2,3:
            pushObj["data"] := StrGet(data,"UTF-8")
        Default: 
            pushObj["data"] := data
    }

    this.easyHandleMap[easy_handle]["callbacks"]["debug"]["log"].push(pushObj)
    return 0
}

_SSLExportCallbackFunction(easy_handle, retArrPtr, session_key, shmac , shmac_len, sdata, sdata_le, valid_until, ietf_tls_id, alpn, earlydata_max){
    ;get the array from the main function
    retArr := ObjFromPtrAddRef(retArrPtr)

    ;process the data
    retMap := Map()
    retMap["session_key"] := StrGet(session_key,"UTF-8")

    shmacBuf := Buffer(shmac_len)
    DllCall("RtlMoveMemory"
            ,   "Ptr", shmacBuf    ;destination
            ,   "Ptr", shmac  ;source
            ,   "UPtr", shmac_len)  ;length
    retMap["shmac"] := this.EncodeBase64(shmacBuf)

    sdataBuf := Buffer(sdata_le)
    DllCall("RtlMoveMemory"
            ,   "Ptr", sdataBuf    ;destination
            ,   "Ptr", sdata  ;source
            ,   "UPtr", sdata_le)  ;length
    retMap["sdata"] := this.EncodeBase64(sdataBuf)

    retMap["valid_until"] := valid_until    ;unix epoch ;todo - convert to human time
    retMap["tls_version"] := Format("0x{:04X}", ietf_tls_id)
    retMap["alpn"] := (alpn?StrGet(alpn,"UTF-8"):"")
    retMap["earlydata_max"] := earlydata_max
    
    ;push the data into the main function's array
    retArr.push(retMap)

    return 0
}
_mimeDataReadCallbackFunction(retBuffer, size, nitems, mime_part){
    partMap := this.mimePartMap[mime_part]
    remainingBytes := partMap["content"].size - partMap["offset"]
    bytesToWrite := Min(size * nitems,remainingBytes)

    DllCall("kernel32.dll\RtlMoveMemory"
        ,   "Ptr",  retBuffer
        ,   "Ptr",  partMap["content"].ptr + partMap["offset"]
        ,   "UInt", bytesToWrite)

    partMap["offset"] += bytesToWrite

    return bytesToWrite
}
 
_mimeDataSeekCallbackFunction(mime_part, offset, origin){
    partMap := this.mimePartMap[mime_part]

    ;validate the offset
    if (partMap["offset"] < 0
    || partMap["offset"] > partMap["content"].size)
        return 2    ;CURL_SEEKFUNC_CANTSEEK
    
    ;process the offset
    switch origin {
        case 0: ;directly set (SEEK_SET)
            partMap["offset"] := offset
        case 1: ;positive seek (SEEK_CUR)
            partMap["offset"] += offset
        case 2: ;negative seek (SEEK_END)
            partMap["offset"] := partMap["content"].size + offset
        default: 
            return 1    ;CURL_SEEKFUNC_FAIL
    }

    return 0
}

_mimeDataFreeCallbackFunction(mime_part){
    ; todo - check if I can fully cleanup the mime_parts in this callback

    ; partMap := this.mimePartMap[mime_part]
    ; partMap["content"] := unset
    ; partMap["offset"] := unset
    ; for k,v in partMap["callbacks"]
    ;     CallbackFree(v)
    ; return 0
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
            this._FreeSList(ptrSList)
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

_ErrorHandler(callingMethod,curlErrorCodeFamily,invokedCurlFunction,incomingValue := 0,errorBuffer?,relevant_handle?){
    ;captures a snapshot when the libcurl DLL reports an error
    ;use _ErrorHierarchy to trace LibQurl method calls

    if !incomingValue
        return 0

    thisError := Map()
    thisError["timestamp"] := A_NowUTC
    
    callingMethod := StrReplace(callingMethod,"LibQurl.Prototype.")
    thisError["invoked LibQurl method"] := callingMethod
    thisError["invoked curl function"] := invokedCurlFunction

    thisError["error family"] := curlErrorCodeFamily
    thisError["error code"] := incomingValue

    thisError["options snapshot"] := []

    switch curlErrorCodeFamily, "Off" {
        case "CURLcode":
            thisError["error string1"] := this.GetErrorString(incomingValue)
            thisError["error string2"] := StrGet(errorBuffer,"UTF-8")
            thisError["options snapshot"].push(this._DeepClone(this.easyHandleMap[relevant_handle]["options"]))
            ;todo - gather nested CURLE_PROXY struct
        case "CURLMcode":
            ; thisError["options snapshot"].InsertAt(1,this._DeepClone(this.multiHandleMap[relevant_handle]["options"]))
        case "CURLSHcode":
            thisError["error string"] := this.GetShareErrorString(incomingValue)
            thisError["options snapshot"].push(this._DeepClone(this.shareHandleMap[relevant_handle]["options"]))
        case "CURLUcode":
            thisError["error string"] := this.GetUrlErrorString(incomingValue)
            thisError["options snapshot"].InsertAt(1,this._DeepClone(this.urlHandleMap[relevant_handle]["options"]))
        case "CURLHcode":
    }

    this.caughtErrors.push(thisError)
}
_ErrorHierarchy(callingMethod,curlErrorCodeFamily,relevant_handle?){
    callingMethod := StrReplace(callingMethod,"LibQurl.Prototype.")

    thisError := this.caughtErrors[-1]
    thisError["invoked LibQurl method"] := callingMethod "\" thisError["invoked LibQurl method"]

    switch curlErrorCodeFamily, "Off" {
        case "CURLcode":
            thisError["options snapshot"].InsertAt(1,this._DeepClone(this.easyHandleMap[relevant_handle]["options"]))
            ;todo - gather nested CURLE_PROXY struct
        case "CURLMcode":
            thisError["options snapshot"].InsertAt(1,this._DeepClone(this.multiHandleMap[relevant_handle]["options"]))
        case "CURLSHcode":
            thisError["options snapshot"].InsertAt(1,this._DeepClone(this.shareHandleMap[relevant_handle]["options"]))
        case "CURLUcode":
            thisError["options snapshot"].InsertAt(1,this._DeepClone(this.urlHandleMap[relevant_handle]["options"]))
        case "CURLHcode":
            ; thisError["options snapshot"].InsertAt(1,this._DeepClone(this.shareHandleMap[relevant_handle]["options"]))
    }
}

; Returns a Buffer object containing the string.
_StrBuf(str, encoding := "cp0")
{
    ; Calculate required size and allocate a buffer.
    buf := Buffer(StrPut(str, encoding))
    ; Copy or convert the string.
    StrPut(str, buf,, encoding)
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
    easy_handle ??= this.easyHandleMap[0][1]   ;defaults to the first created easy_handle

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
    switch bodyObj["writeType"] {
        case "memory", "magic-memory":
            lastBody := bodyObj["writeTo"]
        case "file", "magic-file":
            lastBody := FileOpen(bodyObj["filename"],"rw")
    }
    this.easyHandleMap[easy_handle]["lastBody"] := lastBody
    
    ;accessibly attach headers to easy_handle output
    headerObj := this.easyHandleMap[easy_handle]["callbacks"]["header"]
    lastHeaders := (headerObj["writeType"]="memory"?headerObj["writeTo"]:FileOpen(headerObj["filename"],"rw"))
    this.easyHandleMap[easy_handle]["lastHeaders"] := lastHeaders

    ;record http status code
    this.easyHandleMap[easy_handle]["statusCode"] := this.GetInfo("RESPONSE_CODE",easy_handle)
}
; _QueryPerformanceCounter(){
;     ; https://learn.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
;     liPerformanceCount := Buffer(8)
;     DllCall("QueryPerformanceCounter", "Ptr", liPerformanceCount)
;     return NumGet(liPerformanceCount, 0, "Int64")
; }
_findDLLfromAris(){ ;dynamically finds the dll from a versioned Aris installation
    If DirExist(A_ScriptDir "\lib\Aris\Qriist") ;"top level" install
        packageDir := A_ScriptDir "\lib\Aris\Qriist"
    else if DirExist(A_ScriptDir "\..\lib\Aris\Qriist") ;script one level down
        packageDir := A_ScriptDir "\..\lib\Aris\Qriist"
    else
        return ""
    loop files (packageDir "\LibQurl@*") , "D"{
        LQdir := packageDir "\" A_LoopFileName
    }
    return LQdir "\bin\libcurl.dll"
}

; _findDLLfromAris_hash(){ ;dynamically finds the dll from a versioned Aris installation
;     hash := SHA512("Qriist/LibQurl")
;     If (IsSet(SHA12))
;     return LQdir "\bin\libcurl-x64.dll"
; }

_RefreshEasyHandleForAsync(easy_handle?){    ;this soft-resets the handle without breaking the connection
    easy_handle ??= this.easyHandleMap[0][1]   ;defaults to the first created easy_handle
    ; this._prepareInitCallbacks(easy_handle)
    ; this._setCallbacks(1,1,1,1,,easy_handle) ;don't enable debug by default
    this.HeaderToMem(0,easy_handle)    ;automatically save lastHeader to memory
    
    ;todo - gather and clean the SetOpts
}

_getDllAddress(dllPath,dllfunction){
    return DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", dllPath, "Ptr"), "AStr", dllfunction, "Ptr")
}

_configureSSL(requestedSSLprovider := "WolfSSL"){
    ;probe SSLs
    ret := this._curl_global_sslset(id := 0,name := "",&avail)
    this.availableSSLproviders := this.struct.curl_ssl_backend(avail)
    
    if (ret = 3){
        this.selectedSSLprovider := "This version of libcurl was not built with SSL capabilities."
        return
    }
    

    ;currently known SSLs in the curl source
    ;the user's requested string is the first provider, even if it already exists
    listOfSSLs := [ requestedSSLprovider    
        ;insert any new providers BELOW this line

        ,   "WolfSSL"           ; id = 7
        ,   "OpenSSL"           ; id = 1 (plus any of its forks)
        ,   "Schannel"          ; id = 8
        ,   "GnuTLS"            ; id = 2
        ,   "mbedTLS"           ; id = 11
        ; ,   "RustLS"            ; id = 14

        ;insert any new providers ABOVE this line
        ,   ""]                 ;fallback on whatever curl has
    
    for k,v in listOfSSLs {
        ret := this._curl_global_sslset(id := 0,v,&avail)
    }   until (ret = 0)

    sslHaystack := this.GetVersionInfo()["ssl_version"]
    pos := RegExMatch(sslHaystack,"(?:^| )([A-Za-z\/0-9\\.]+)",&captured)    
    this.selectedSSLprovider := captured[1]
}
_globalCleanup(){   ;this should be called when shutting down LibQurl
    ;delete any flushed magic-files
    If DirExist(A_Temp "\LibQurl") {
        ;per easy_handle to avoid stepping on other instances of the class
        for k,v in this.easyHandleMap[0]
            FileDelete(A_Temp "\LibQurl\*." v)

        ;attempt to clean the temp folder itself, but silently fail if temp files remain
        try DirDelete(A_Temp "\LibQurl")
    }
    
    this._curl_global_cleanup()
}
_register(dllPath?,requestedSSLprovider?) {
    ;todo - make dll auto-load feature more robust
    ;determine where the dll will load from
    if !FileExist(dllPath ??= "")
        dllPath := this._findDLLfromAris()  ;will try to fallback on the installed package directory
    if !FileExist(dllPath)
        dllPath := A_ScriptDir "\bin\libcurl.dll"   ;"top level" script
    if !FileExist(dllPath)
        dllPath := A_ScriptDir "\..\bin\libcurl.dll" ;script one level down (AKA test folder)
    if !FileExist(dllPath)
        throw ValueError("libcurl DLL not found!", -1, dllPath)

    ;save the current working dir so we can safely load the DLL
    oldWorkingDir := A_WorkingDir
    SplitPath(dllPath,,&dllDir)
    this.dllDir := dllDir
    SetWorkingDir(dllDir)
    
    ;load the DLL into resident memory
    this.curlDLLpath := dllpath
    this.curlDLLhandle := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

    ;restore the user's intended workingDir
    A_WorkingDir := oldWorkingDir
    
    ;continue loading
    this._configureSSL(requestedSSLprovider?)   
    this._curl_global_init()
    OnExit (*) => this._globalCleanup()
    this._declareConstants()
    this._buildOptMap()
    this.mOpt := this.constants["CURLMoption"]
    this.sOpt := this.constants["CURLSHoption"]
    ; msgbox this.PrintObj(this.mopt)
    this.VersionInfo := this.GetVersionInfo()
    this.UrlInit()
    this.MultiInit()
    this.ShareInit()
    
    ;these should be run directly back-to-back
    this.Init(), this._autoUpdateCertFile()
    return
}
_autoUpdateCertFile(){
    SplitPath(this.curlDLLpath,,&dlldir)
    this.crt := crt := dlldir "\curl-ca-bundle.crt"

    ;update the default easy_handle provided by __New()
    ;otherwise it would have no SSL file
    this.SetOpt("CAINFO",crt)

    ; don't try to update for at least 90 days
    If (DateDiff(A_Now,FileGetTime(crt),"Days") < 90)
        return

    etagf := dlldir "\curl-ca-bundle.etag"
    If FileExist(etagf){
        ;don't try to update within 1 day of last attempt
        If (DateDiff(A_Now,FileGetTime(etagf),"Days") < 1)
            return

        etagv := FileOpen(etagf,"r").Read()
    }
    
    ;set the etag value if possible
    this.SetHeaders(Map("If-None-Match",etagv??=""))

    url := "curl.se/ca/cacert.pem"
    this.SetOpt("URL","https://" url)
    this.Sync()
    
    switch this.GetInfo("RESPONSE_CODE") {
        case 304:   ;have the latest bundle
            ;update the etag timestamp
            FileSetTime(A_Now,etagf)
            return
        case 200:   ;there's an updatable bundle
            ; save the cert bundle + etag
            FileOpen(crt,"w").Write(this.GetLastBody())
            etagv := this.InspectHeader("ETag")
            FileOpen(etagf,"w").Write(etagv)

            ;provide a clean handle to the class
            this.Cleanup()
            return
        default:    ;something else happened, do nothing
            return
    }
}
_GetFilePathFromFileObject(FileObject) {
    static GetFinalPathNameByHandleW := DllCall("Kernel32\GetProcAddress", "Ptr", DllCall("Kernel32\GetModuleHandle", "Str", "Kernel32", "Ptr"), "AStr", "GetFinalPathNameByHandleW", "Ptr")

    ; if !FileObject
        ; throw Error("Invalid file handle")

    ; Initialize a buffer to receive the file path
    static bufSize := 65536    ;64kb to accomodate long path names in UTF-16
    buf := Buffer(bufSize)

    ; Call GetFinalPathNameByHandleW
    len := DllCall(GetFinalPathNameByHandleW
        ,   "Ptr", FileObject.handle       ; File handle
        ,   "Ptr", buf         ; Buffer to receive the path
        ,   "UInt", bufSize    ; Size of the buffer (in wchar_t units)
        ,   "UInt", 0          ; Flags (0 for default behavior)
        ,   "UInt")            ; Return length of the file path

    if (len == 0 || len > bufSize)
        throw Error("Failed to retrieve file path or insufficient buffer size", A_LastError)

    ; Return the result as a string
    return StrGet(buf, "UTF-16")
}
_formatHeaders(headersObject){
    ; Pass an array of "Header: value" strings OR a Map of the same.
    ; Use empty value ("Header: ") to disable internally used header.
    ; Use semicolon ("Header;") to add the header with no value.
    switch Type(headersObject) {
        case "Map","Object":
            headersArray := []
            for k,v in this._Enum(headersObject){
                switch {
                    case v="":    ;diabled
                        headersArray.Push(k ": ")
                    case v=";":   ;empty
                        headersArray.Push(k ";")
                    default:
                        headersArray.Push(k ": " v)
                }
        }
        case "Array":
            headersArray := headersObject
    }
    return headersArray
}
_Enum(inObj){   ;simplify rolling over objects
    If (Type(inObj) = "Object")
        return inObj.OwnProps()
    return inobj
}