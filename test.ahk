#requires Autohotkey v2.0
#Include <class_libcurl>
#Warn VarUnset, Off

curl := class_libcurl()
curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

curl.SetOpt("CAINFO",A_ScriptDir "\lib\curl-ca-bundle.crt")

curl.SetOpt("URL","https://httpbin.org/headers")
curl.SetHeaders(Map("jank","extraJank","tidbit","is a header"))
curl.WriteToFile(a_scriptdir "\download\httpbin.json")
curl.Perform()

curl.SetOpt("URL","https://www.titsandasses.org")
curl.WriteToFile(a_scriptdir "\download\titsandasses.html")
curl.Perform()

; curl.SetHeaders(Map("jank","extraJank","tidbit","was here"),desiredhandle)
; curl.Perform(desiredhandle)



; msgbox curl.ListOpts()

; curl.SetOpt("URL","https://www.google.com/images/branding/googlelogo/2x/googlelogo_light_color_272x92dp.png")
; curl.WriteToFile(a_scriptdir "\download\google.png")
; curl.Perform()

; curl.SetOpt("URL","https://www.google.com")
; curl.WriteToFile(a_scriptdir "\download\google.html")
; curl.Perform()

;; known good large binary download
; curl.SetOpt("URL","https://database.lichess.org/standard/lichess_db_standard_rated_2014-07.pgn.zst")
; curl.WriteToFile(a_scriptdir "\download\lichess.zst")
; curl.Perform()

; DllCall(Curl.dllFilename . "\curl_easy_perform", "Ptr", this._handle, "CDecl")
; curl["hCURL"][hCURL]["storageHandle"].open()
; msgbox curl["hCURL"][hCURL]["storageHandle"].write("a")
; msgbox curl["hCURL"][hCURL]["storageHandle"]
; msgbox DllCall("libcurl-x64\curl_easy_perform","Ptr",curl["hCURL"][hCURL]["writeInfo"]["writeTo"])

exitapp


;doge-style code below
; DllCall("GetModuleHandleA","AStr","libcurl-x64.dll") || DllCall("LoadLibraryA","AStr","libcurl-x64.dll") ;replaces #DllLoad libcurl-x64.dll
curl_handle:=DllCall("libcurl-x64\curl_easy_init","Ptr")
; msgbox curl_handle
; CURLcode:=DllCall("libcurl-x64\curl_easy_setopt","Ptr",curl_handle,"Int",64,"Int",1) ;10064=CURLOPT_SSL_VERIFYPEER
CURLcode:=DllCall("libcurl-x64\curl_easy_setopt","Ptr",curl_handle,"Int",10002,"AStr","https://titsandasses.org/") ;10002=CURLOPT_URL=CURLOPTTYPE_OBJECTPOINT+2
CURLcode:=DllCall("libcurl-x64\curl_easy_setopt","Ptr",curl_handle,"Int",10002,"AStr","https://www.google.com") ;10002=CURLOPT_URL=CURLOPTTYPE_OBJECTPOINT+2
CURLcode:=DllCall("libcurl-x64\curl_easy_setopt","Ptr",curl_handle,"Int",10065,"AStr",A_ScriptDir "\lib\curl-ca-bundle.crt") ;10065=CURLOPT_CAINFO
CURLcode:=DllCall("libcurl-x64\curl_easy_perform","Ptr",outw(data)) ;10065=CURLOPT_CAINFO
msgbox CURLcode
exitapp
outw(data){
    FileOpen("test.txt","w").Write(data)
}

/* v1 function path for writing to file
myCurl.SetUrl("https://example.com")    ;uses .setOpt(), unremarkable
myCurl.WriteToFile("example_2_httpget.htm") ;uses the File class
myCurl.Perform()    ;uses everything else below

WriteToFile(filename) {
    Return (this._writeTo := new Curl.Storage.File(filename, "w"))
}
Class File {
    __New(filename, accessMode := "w") {    ;initializes the file handle
        this._filename   := filename
        this._accessMode := accessMode
        this._fileObject := ""
    }
    Open() {
        If (this._accessMode == "w") {
            RegexMatch(this._filename, "^.+(?=[\\\/])", fileDirPath)
            If (fileDirPath)
                FileCreateDir % fileDirPath
            
            this._fileObject := FileOpen(this._filename, this._accessMode, "CP0")
        }
    }
}
Perform() {
    ; Store handle in global pool so callbacks can access the instance
    Curl.activePool[this._handle] := this
    
    ; Prepare callbacks, removing old callbacks if necessary.
    needWriteCallback := True
    this.SetOpt(Curl.Opt.WRITEDATA    , (!needWriteCallback ? 0 : this._handle))
    this.SetOpt(Curl.Opt.WRITEFUNCTION, (!needWriteCallback ? 0 : Curl._CB_Write))
    
    (this._writeTo)   ?  this._writeTo.Open()
    (this._headerTo)  ?  this._headerTo.Open()
    (this._readFrom)  ?  this._readFrom.Open()
    
    ; TODO: cookies? headers?
    retCode := DllCall(Curl.dllFilename . "\curl_easy_perform", "Ptr", this._handle, "CDecl")
    
    (this._writeTo)   ?  this._writeTo.Close()
    (this._headerTo)  ?  this._headerTo.Close()
    (this._readFrom)  ?  this._readFrom.Close()
    
    Curl.activePool.Delete(this._handle)
    
    Return this._SetLastCode(retCode, "Perform")
}
Curl._CB_Write    := RegisterCallback(Curl._WriteCallback    , "CDecl")
    ; Callbacks
; =========
; Note: because those are class methods, arguments are shifted by one,
; and 'this' variable is actually stores the first argument.

_WriteCallback(size, sizeBytes, userdata) {
    dataPtr  := this
    dataSize := size * sizeBytes
    curlInstance := Curl.activePool[userdata]
    
    ; User callback
    userCallbackReply := ""
    If (curlInstance.OnWrite) {
        userCallbackReply := curlInstance.OnWrite.Call(dataPtr, dataSize, curlInstance)
    }
    
    ; If (userCallbackReply = "Pause")
    ; 	Return 0x10000001  ; CURL_WRITEFUNC_PAUSE
    
    If (userCallbackReply != "")
        Return userCallbackReply
    
    If (curlInstance._writeTo) {
        n := curlInstance._writeTo.RawWrite(dataPtr, dataSize)
        Return n
    }
    Return dataSize
}
SetOpt(optionId, argument, argType := "") {
    ;                  1:LONG 2:OBJP 3:STRP  4:SLIP 5:FUNP 6:OFFT   7:BLOB
    Static argTypes := ["Int", "Ptr", "AStr", "Ptr", "Ptr", "Int64", "Ptr"]
    Static AHK_ARG  := 100000  ; See Curl.Opt.Init
    
    If (argType == "") {
        argTypeN := optionId // AHK_ARG
        argType  := argTypes[argTypeN]
        
        If (argTypeN == 4) {
            Curl._FreeSList( this._usedLists[optionId] )  ; Remove previous linked-list (if any)
            argument := Curl._ArrayToSList(argument)      ; Convert array to linked-list
            this._usedLists[optionId] := argument         ; Put to trash bin for eventual cleanup
        }
    }
    
    optionId := Mod(optionId, AHK_ARG)
    retCode := DllCall(Curl.dllFilename . "\curl_easy_setopt"
    , "Ptr"  , this._handle
    , "Int"  , optionId
    , argType, argument
    , "CDecl Int")
    
    Return this._SetLastCode(retCode, "OPT:" . optionId)
}
*/

CURLcode:=DllCall("libcurl-x64\curl_easy_perform","Ptr",curl_handle)

exitapp



msgbox curl._curl_easy_perform(hCURL)
;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]
exitapp
msgbox showob(curl.opt)

hCURL := curl._curl_easy_init()
jank := "Copyright © DotNetTutorials"
curl._curl_easy_escape(hCURL,jank)
exitapp
;msgbox hCURL
curl._curl_easy_reset(hCURL)
curl._buildOptMap()
msgbox curl.opt["URL"]["id"] "`n" 
    .   curl.opt[2]["id"] "`n" 
    .   curl.opt["CURLOPT_URL"]["id"] "`n" 
    .   curl.opt[10002]["id"]



name := "WILDCARDMATCH"
byName := curl._curl_easy_option_by_name(name)
; msgbox StrGet(NumGet(ByName,"Ptr"),"UTF-8")
; MSGBOX 
; msgbox NumGet(ByName,(floor(strlen(name)/8)+1)*8,"UInt")

;msgbox "curlDLLhandle (from LoadLibrary): " curl.curlDLLhandle "`ncurl_easy_option_by_name (from libcurl): " byName
;msgbox NumGet(byName,"Str")

exitapp
curl._curl_easy_setopt(hCURL,byName,"https://example.com")

; curl._curl_easy_setopt(hCURL,"CURLOPT_URL","https://www.google.org:80/")
msgbox curl._curl_easy_perform(hCURL)


curl.register(A_ScriptDir "\lib\libcurl-x64.dll")

;msgbox curl._curl_version()
; msgbox curl._curl_version_info()["age"]

hCURL := curl._curl_easy_init()
;msgbox hCURL
curl._curl_easy_reset(hCURL)

; msgbox curl.curl_easy_escape(hCURL,"hhttps://www.google.org")
byName := curl._curl_easy_option_by_name("URL")
msgbox StrGet(NumGet(ByName,"Ptr"),"UTF-8")


; struct curl_easyoption {
;     const char *name;
;     CURLoption id;
;     curl_easytype type;
;     unsigned int flags;
;   };

class curl_easyoption {  ; This type can also be used in a struct.
    name : uptr
    id : uint
    size => DllCall("oleaut32\SysStringByteLen", "ptr", this, "uint")
    __value {
        get => StrGet(this)
        set {
            if this.name  ; In case of use in a struct.
                this.__delete()
            this.name := DllCall("oleaut32\SysAllocStringLen", "wstr", value, "uint", StrLen(value), "ptr")
        }
    }
    __delete => DllCall("oleaut32\SysFreeString", "ptr", this)
}


ShowOB(ob,strOB:="") {  ; returns `n list.  pass object, returns list of elements. nice chart format with `n.  strOB for internal use only.
	(Type(Ob) ~= 'Object|Gui')	? Ob := Ob.OwnProps() : 1
	for i, v in ob
		(!isobject(v))	? ( rets .= "`n [" strOB i "] = [" v "]" ) : ( rets .= ShowOB(v,strOB i "."))
	return isSet(rets)?rets:""
}

class Struct
{
    static __types := {UInt: 4, UInt64: 8, Int: 4, Int64: 8, Short: 2, UShort: 2, Char: 1, UChar: 1, Double: 8, Float: 4, Ptr: A_PtrSize, UPtr: A_PtrSize}
    __New(structinfo, ads_pa := unset, offset := 0, bit64 := unset) {
        if (IsSet(bit64))
            types := struct.__types.Clone(), types.Ptr := types.UPtr := 4 * (!!bit64 + 1)
        else types := struct.__types, bit64 := A_PtrSize = 8
        maxbytes := 0, index := 0, root := true, level := 0, sub := [], this.DefineProp('__bit64', {Value: bit64})
        this.DefineProp("__member", {Value: {}}), this.DefineProp("__buffer", {Value: {Ptr: 0, Size: 0}}), this.DefineProp("__memberlist", {Value: []})	; this.__member:={}, this.__buffer:=""
        this.DefineProp('__types', {Value: types}), this.DefineProp("__base", {Value: (IsSet(ads_pa) && Type(ads_pa) = "Buffer") ? (root := false, ads_pa) : Buffer(A_PtrSize, 0)})
        if (Type(structinfo) = "String") {
            structinfo := Trim(RegExReplace(structinfo, '//.*'), '`n`r`t ')
            structinfo := RegExReplace(structinfo := StrReplace(structinfo, ",", "`n"), "m)^\s*unsigned\s*", "U")
            structinfo := StrSplit(structinfo, "`n", "`r `t")
        }
        while (index < structinfo.Length) {
            index++, LF := structinfo[index]
            if (LF ~= "^(typedef\s+)?struct\s*") {
                if (index > 1) {
                    level++, submax := 0, sub.Length := 0, name := RegExMatch(LF, 'struct\s+(\w+)', &n) ? n[1] : ''
                    while (level) {
                        index++, LF := structinfo[index]
                        if InStr(LF, "{")
                            level++
                        else if InStr(LF, "}") && ((--level) = 0) {
                            if !RegExMatch(LF, "\}\s*(\w+)", &n)
                                throw Error("structure's name not found")
                            break
                        } else if RegExMatch(LF, "^(\w+)\s*(\*+)?\s*(\w+)(\[\d+\])?", &m)
                            _type := this.ahktype(m[1] m[2]), submax := Max(submax, types.%_type%), LF := _type " " m[3] m[4]
                        sub.Push(LF)
                    }
                    offset := Mod(offset, submax) ? (Integer(offset / submax) + 1) * submax : offset
                    this.__memberlist.Push(n[1]), this.__member.%n[1]% := tmp := struct(sub, this.__base, offset)
                    tmp.DefineProp('__structname', {Value: name})
                    offset := tmp.__offset + tmp.__buffer.Size, maxbytes := Max(maxbytes, tmp.__maxbytes)
                } else
                    this.DefineProp('__structname', {Value: RegExMatch(LF, 'struct\s+(\w+)', &n) ? n[1] : ''})
                continue
            }
            if RegExMatch(LF, "^(\w+)\s*(\*+)?\s*(\w+)(\[\d+\])?", &m) {
                _type := root ? this.ahktype(m[1] m[2]) : m[1]
                b := types.%_type%, maxbytes := Max(maxbytes, b), offset := Mod(offset, b) ? (Integer(offset / b) + 1) * b : offset
                if !IsSet(firstmember)
                    firstmember := offset
                this.DefineProp("__maxbytes", {Value: maxbytes}), this.__memberlist.Push(m[3])
                if (n := Integer("0" Trim(m[4], "[]")))
                    this.__member.%m[3]% := {type: _type, offset: offset, size: n}, offset += b * n
                else
                    this.__member.%m[3]% := {type: _type, offset: offset}, offset += b
            }
        }
        offset := Mod(offset - firstmember, maxbytes) ? ((Integer((offset - firstmember) / maxbytes) + 1) * maxbytes + firstmember) : offset
        this.DefineProp("__offset", {Value: firstmember})
        if IsSet(ads_pa) {
            if Type(ads_pa) = "Buffer"
                (this.__buffer := {Size: offset - firstmember}).DefineProp("Ptr", {get: ((p, o, *) => NumGet(p, "Ptr") + o).Bind(ads_pa.Ptr, firstmember)})
            else
                this.__buffer := {Ptr: Integer(ads_pa), Size: offset - firstmember}, NumPut("Ptr", ads_pa, this.__base)
        } else NumPut("Ptr", (this.__buffer := Buffer(offset - firstmember, 0)).Ptr, this.__base)

        for m in this.__member.OwnProps()
        ; this.__member.%m%.DefineProp("value", {get: ((n, *) => this.%n%).Bind(m)})
            if (Type(this.__member.%m%) = "Object") {
                offset := this.__member.%m%.offset - this.__offset
                _type := this.__member.%m%.type
                this.DefineProp(m, {
                    get: ((o, t, s, p*) => (p.Length ? NumGet(s.__buffer.Ptr, o + p[1] * types.%t%, t) : NumGet(s.__buffer.Ptr, o, t))).Bind(offset, _type),
                    set: ((o, t, s, v, p*) => (p.Length ? NumPut(t, v, s.__buffer.Ptr, o + p[1] * types.%t%) : NumPut(t, v, s.__buffer.Ptr, o))).Bind(offset, _type)
                })
            } else
                this.DefineProp(m, {get: ((n, s, p*) => s.__member.%n%).Bind(m)})
    }
    ; __Get(n, params) {
    ; 	if (Type(this.__member.%n%) = "Object") {
    ; 		offset := this.__member.%n%.offset - this.__offset
    ; 		if params.Length {
    ; 			if (params[1] >= this.__member.%n%.size)
    ; 				throw Error("Invalid index")
    ; 			offset += params[1] * this.__types.%(this.__member.%n%.type)%
    ; 		}
    ; 		return NumGet(this.__buffer.Ptr, offset, this.__member.%n%.type)
    ; 	} else return this.__member.%n%
    ; }
    ; __Set(n, params, v) {
    ; 	if (Type(this.__member.%n%) = "Object") {
    ; 		offset := this.__member.%n%.offset - this.__offset
    ; 		if params.Length {
    ; 			if (params[1] >= this.__member.%n%.size)
    ; 				throw Error("Invalid index")
    ; 			offset += params[1] * this.__types.%(this.__member.%n%.type)%
    ; 		}
    ; 		NumPut(this.__member.%n%.type, v, this.__buffer.Ptr, offset)
    ; 	} else throw Error("substruct '" n "' can't be overwritten")
    ; }
    data() => this.__buffer.Ptr
    offset(n) => this.__member.%n%.offset
    size() => this.__buffer.Size
    __Delete() => (this.__base := this.__buffer := this.__memberlist := this.__member := '')

    toString() {
        _str := "// total size:" this.__buffer.Size "  (" ((!!this.__bit64 + 1) * 32) " bit)`nstruct {`n", Dump(this)
        return _str "};"

        Dump(obj, _indent := 1) {
            for m in obj.__memberlist {
                if ("Object" = _t := Type(n := obj.__member.%m%))
                    _str .= Indent(_indent) StrLower(n.Type) "`t" m (n.HasOwnProp("size") ? "[" n.size "]" : "") ";`t// " n.offset "`n"
                else if (_t = "struct") {
                    _str .= Indent(_indent) "// struct '" m "' size:" n.__buffer.Size "`n" Indent(_indent) "struct {`n"
                    Dump(n, _indent + 1)
                    _str .= Indent(_indent) "} " m ";`n"
                }
            }
        }
        Indent(n := 0) {
            Loop (_ind := "", n)
                _ind .= "`t"
            return _ind
        }
    }

    generateClass() {
        a := generate(this), s := Trim(RegExReplace(RegExReplace(this.toString(), '//(.*)'), '\R\R', '`n'), ' `t`n')
        if (!RegExMatch(s, 'im)^\s*ptr\s+'))
            return a
        b := generate(struct(s, 0, , !this.__bit64)), s := a
        a := StrSplit(a, '`n'), b := StrSplit(b, '`n')
        if (a.Length != b.Length) {
            MsgBox('Error')
            return s
        }
        s := ''
        loop a.Length {
            if (a[A_Index] != b[A_Index] && RegExMatch(a[A_Index], '([,(]\s*)?\b(\d+)\b', &m1) && RegExMatch(b[A_Index], '\b(\d+)\b', &m2) && m1 != m2) {
                t := 'A_PtrSize = 8 ? ' Max(m1[2], m2[1]) ' : ' Min(m1[2], m2[1])
                s .= RegExReplace(a[A_Index], m1[2], m1[1] ? t : '(' t ')', , 1) '`n'
            } else
                s .= a[A_Index] '`n'
        }
        return s

        generate(obj) {
            cl := 'class ' obj.__structname ' {`n`t__New() {`n`t`tthis.__buf := Buffer(' obj.size() '), this.ptr := this.__buf.Ptr`n`t}`n'
            cl := cl Dump(obj) '}'
            return cl
            Dump(obj, _indext := 1) {
                local s := ''
                for m in obj.__memberlist {
                    if ("Object" = _t := Type(n := obj.__member.%m%))
                        s .= Indent(_indext) m ' {`n' Indent(_indext + 1) 'get => NumGet(this.ptr, ' (n.offset - obj.__offset) ', `'' StrLower(n.Type) '`')`n' Indent(_indext + 1) 'set => NumPut(`'' StrLower(n.Type) '`', value, this.ptr, ' (n.offset - obj.__offset) ')`n' Indent(_indext) '}`n'
                    else if (_t = 'struct') {
                        c := 'class ' (n.__structname || m) ' {`n`t__New() {`n`t`tthis.__buf := Buffer(' n.size() '), this.ptr := this.__buf.Ptr`n`t}`n'
                        c .= Dump(n) '}`n'
                        cl := c cl
                        s .= Indent(_indext) m ' => {Base: ' (n.__structname || m) '.Prototype, ptr: this.ptr + ' n.__offset ', __buf: this.__buf}`n'
                    }
                }
                return s
            }
            Indent(n := 0) {
                loop (_ind := '', n)
                    _ind .= '`t'
                return _ind
            }
        }
    }

    ahktype(t) {
        if (!this.__types.HasOwnProp(_type := LTrim(t, "_"))) {
            switch (_type := StrUpper(_type))
            {
                case "BYTE", "BOOLEAN":
                    _type := "UChar"
                case "ATOM", "LANGID", "WORD", "TBYTE", "TCHAR", "WCHAR", "WCHAR_T", "INTERNET_PORT":
                    _type := "UShort"
                case "BOOL", "HFILE", "HRESULT", "INT32", "LONG", "LONG32", "INTERNET_SCHEME":
                    _type := "Int"
                case "UINT32", "ULONG", "ULONG32", "COLORREF", "DWORD", "DWORD32", "LCID", "LCTYPE", "LGRPID":
                    _type := "UInt"
                case "LONG64", "LONGLONG", "USN":
                    _type := "Int64"
                case "DWORD64", "DWORDLONG", "ULONG64", "ULONGLONG":
                    _type := "UInt64"
                default:
                    if InStr(_type, "*")
                        return "Ptr"
                    _U := (_type ~= "^U[^uU]\w+$" ? ((_type := LTrim(_type, "U")), true) : false)
                    if (_type == "HALF_PTR")
                        _type := (_U ? "U" : "") (A_PtrSize = 8 ? "Int" : "Short")
                    else if (_type ~= "^(\w+_PTR|[WL]PARAM|LRESULT|(H|L?P)\w+|SC_(HANDLE|LOCK)|S?SIZE_T|VOID)$")
                        _type := (_U ? "U" : "") "Ptr"
                    if (!this.__types.HasOwnProp(_type))
                        throw Error("unsupport type: " _type)
            }
        }
        return _type
    }
}


