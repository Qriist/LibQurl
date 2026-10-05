hash(&item := "", hashType := "", c_size := "", cb := "") { ; default hashType = SHA256 /// default enc = UTF-16
    static _hLib := DllCall("LoadLibrary", "Str", "bcrypt.dll", "UPtr"), LType := "SHA256", LItem := "", LBuf := "", LSize := "", d_LSize :=
    1024000
    static n := { hAlg: 0, hHash: 0, size: 0, obj: "" }
    , o := { md2: n.Clone(), md4: n.Clone(), md5: n.Clone(), sha1: n.Clone(), sha256: n.Clone(), sha384: n.Clone(), sha512: n.Clone() }
    _file := "", LType := (hashType ? StrUpper(hashType) : LType), LItem := (item ? item : LItem), ((!o.%LType%.hAlg) ? make_obj() : "")

    if(!item && !hashType) { ; Free buffers/memory and release objects.
        return !graceful_exit()
    } else if(Type(LItem) = "File") { ; Determine buffer type.
        _file := LItem, LBuf := true, LSize := (c_size ? c_size : d_LSize)
    } else if(Type(item) = "String") || (Type(item) = "Integer") {
        LBuf := Buffer(StrPut(item, "UTF-8") - 1, 0), LItem := "", LSize := d_LSize
        temp_buf := Buffer(LBuf.size + 1, 0), StrPut(item, temp_buf, "UTF-8"), copy_str()
    } else if(Type(item) = "Buffer")
        LBuf := item, LItem := "", LSize := d_LSize

    if(LBuf && !(outVal := "")) {
        hDigest := Buffer(o.%LType%.size) ; Create new digest obj
        loop t := (!_file ? 1 : (_file.Length // LSize) + 1)
            (_file ? _file.RawRead(LBuf := Buffer(((_len := _file.Length - _file.Pos) < LSize) ? _len : LSize, 0)) : "")
                , r7 := DllCall("bcrypt\BCryptHashData", "UPtr", o.%LType%.obj.ptr, "UPtr", LBuf.ptr, "UInt", LBuf.size, "UInt", 0)
                , ((Type(cb) = "Func") ? cb(A_index / t) : "")
        r8 := DllCall("bcrypt\BCryptFinishHash", "UPtr", o.%LType%.obj.ptr, "UPtr", hDigest.ptr, "UInt", hDigest.size, "UInt", 0)
        loop hDigest.size ; convert hDigest to hex string
            outVal .= Format("{:02X}", NumGet(hDigest, A_Index - 1, "UChar"))
    }

    _file ? (_file.Close(), LBuf := "") : ""
    return outVal

    make_obj() { ; create hash object
        r1 := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "UPtr*", &hAlg := 0, "Str", LType, "UPtr", 0, "UInt", 0x20) ; BCRYPT_HASH_REUSABLE_FLAG = 0x20

        r3 := DllCall("bcrypt\BCryptGetProperty", "UPtr", hAlg, "Str", "ObjectLength"
            , "UInt*", &objSize := 0, "UInt", 4, "UInt*", &_size := 0, "UInt", 0) ; Just use UInt* for bSize, and ignore _size.

        r4 := DllCall("bcrypt\BCryptGetProperty", "UPtr", hAlg, "Str", "HashDigestLength"
            , "UInt*", &hashSize := 0, "UInt", 4, "UInt*", &_size := 0, "UInt", 0), obj := Buffer(objSize)

        r5 := DllCall("bcrypt\BCryptCreateHash", "UPtr", hAlg, "UPtr*", &hHash := 0       ; Setup fast reusage of hash obj...
            , "UPtr", obj.ptr, "UInt", obj.size, "UPtr", 0, "UInt", 0, "UInt", 0x20) ; ... with 0x20 flag.

        o.%LType% := { obj: obj, hHash: hHash, hAlg: hAlg, size: hashSize }
        return ""   ;required to prevent unset
    }

    graceful_exit(r1 := 0, r2 := 0) {
        for name, obj in o.OwnProps() {
            if o.%name%.hHash && (r1 := DllCall("bcrypt\BCryptDestroyHash", "UPtr", o.%name%.hHash)
            || r2 := DllCall("bcrypt\BCryptCloseAlgorithmProvider", "UPtr", o.%name%.hAlg, "UInt", 0))
                throw Error("Unable to destroy hash object.")
            o.%name%.hHash := o.%name%.hAlg := o.%name%.size := 0, o.%name%.obj := ""
        }
        LBuf := "", LItem := "", LSize := c_size
    }

    copy_str() => DllCall("NtDll\RtlCopyMemory", "UPtr", LBuf.ptr, "UPtr", temp_buf.ptr, "UPtr", LBuf.size)
}

hashObj(inObj, nohash := 0, resultArr := [], ptrMap := Map(), top := 1) {

    static para := {
        Object: { Start: "Object{", End: "}" },
        Map: { Start: "Map(", End: ")" },
        Array: { Start: "Array[", End: "]" },
        Buffer: { Start: "Buffer|", End: "|" },
        File: { Start: 'File"', End: '"' },
        Null: { Start: "Null<", End: ">" }
    }

    ; ;safe return
    if !IsObject(inObj)
        return this.hash(&inObj, "SHA512")

    ;catch circular references
    ptr := ObjPtr(inObj)
    if ptrMap.Has(ptr)
        return resultArr.push("DEREF")
    ptrMap[ptr] := 1

    ;define how objects get serialized
    inType := Type(inObj)
    parastart := (para.HasProp(inType) ? para.%inType%.Start : inType "*")
    paraend := (para.HasProp(inType) ? para.%inType%.End : "*")

    switch inType {
        case "Null":
            resultArr.Push(parastart)  ;object open
            resultArr.Push("+x00::NULL=")
            resultArr.Push(paraend)    ;object close
        Default:
            resultArr.Push(parastart)  ;object open

            ; process .properties
            for k, v in inObj.OwnProps() {
                if IsObject(v) {

                    resultArr.Push("." k ":")
                    this.hashObj(v, nohash, resultArr, ptrMap, 0)
                } else {
                    ; val := (!nohash ? hash(&v,) : v)
                    val := (!nohash ? this.hash(&v, "SHA512") : nohash = 1 ? v : this.hash(&v, "SHA512"))
                    switch Type(v) {
                        case "Integer":
                            resultArr.Push("." k ":!:" val "=")
                        case "Float":
                            resultArr.Push("." k ":@:" val "=")
                        case "String":
                            resultArr.Push("." k ":" StrPut(v) ":" val "=")
                    }
                }
            }

            ; process ["keys"]
            if InObj.HasProp("__Item") {
                for k, v in inObj {
                    if IsObject(v) {
                        resultArr.Push("/" k ":")
                        this.hashObj(v, nohash, resultArr, ptrMap, 0)
                    } else
                        val := (!nohash ? this.hash(&v, "SHA512") : nohash = 1 ? v : this.hash(&v, "SHA512"))
                    switch Type(v) {
                        case "Integer":
                            resultArr.Push("/" k ":!:" val "=")
                        case "Float":
                            resultArr.Push("/" k ":@:" val "=")
                        case "String":
                            resultArr.Push("/" k ":" StrPut(v) ":" val "=")
                    }
                }
            }

            ;get the meat of Buffer and File objects
            switch inType {
                case "Buffer":
                    val := (!nohash ? this.hash(&inObj, "SHA512") : nohash = 1 ? "[BUFFER]" : this.hash(&inObj, "SHA512"))
                    resultArr.Push("+" inobj.size ":|:" val "=")
                case "File":
                    hashfile := this._GetFilePathFromFileObject(inObj)
                    hashfile := FileOpen(hashfile, "r")
                    val := (!nohash ? this.hash(&hashfile, "SHA512") : nohash = 1 ? "[FILE]" : this.hash(&inObj, "SHA512"))
                    resultArr.Push("+" hashfile.Length ":-:" val "=")
            }

            resultArr.Push(paraend)    ;object close
    }

    ; prevent sub objects from finalizing
    if !top
        return ""

    ;export
    concat := ""
    VarSetStrCapacity(&concat, resultArr.Length * 256)
    for k, v in resultArr
        concat .= v

    if nohash
        return concat
    return this.hash(&concat, "SHA512")
}
