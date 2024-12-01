﻿;This file generally contains the little methods that support core functionality.
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