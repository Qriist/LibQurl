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

_ErrorHandler(callingMethod,curlErrorCodeFamily,invokedCurlFunction,incomingValue := 0,errorBuffer?,relevant_handle?){
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
        case "CURLSHcode":
            thisError["error string"] := this.GetShareErrorString(incomingValue)
            thisError["options snapshot"].push(this._DeepClone(this.shareHandleMap[relevant_handle]["options"]))
        case "CURLUcode":
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
        case "CURLHcode":
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

; _findDLLfromAris_hash(){ ;dynamically finds the dll from a versioned Aris installation
;     hash := SHA512("Qriist/LibQurl")
;     If (IsSet(SHA12))
;     return LQdir "\bin\libcurl-x64.dll"
; }

_RefreshEasyHandleForAsync(easy_handle?){    ;this soft-resets the handle without breaking the connection
    easy_handle ??= this.easyHandleMap[0][-1]   ;defaults to the last created easy_handle
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
        ,   "SecureTransport"   ; id = 9
        ,   "mbedTLS"           ; id = 11
        ,   "BearSSL"           ; id = 13
        ,   "RustLS"            ; id = 14

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
    this._curl_global_cleanup()
}