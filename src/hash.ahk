hash(&item := "", hashType := "", c_size := "", cb := "") { ; default hashType = SHA256, strings hashed as UTF-8
    static _hLib := DllCall("LoadLibrary", "Str", "bcrypt.dll", "UPtr")
    , LType := "SHA256", LItem := "", LBuf := "", LSize := "", d_LSize := 1024000
    static n := { hAlg: 0, hHash: 0, size: 0, obj: "" }
    , o := { md2: n.Clone(), md4: n.Clone(), md5: n.Clone(), sha1: n.Clone(), sha256: n.Clone(), sha384: n.Clone(), sha512: n.Clone() }
    _file := "", outVal := ""
    LType := hashType ? StrUpper(hashType) : LType
    LItem := item ? item : LItem
    if !o.%LType%.hAlg
        make_obj()

    if(!item && !hashType)
        return !graceful_exit()
    else if(Type(LItem) = "File") {
        path := this._GetFilePathFromFileObject(LItem)
        _file := FileOpen(path, "r")
        _file.Seek(0) ; hash the whole file, not from the current pointer
        LBuf := true
        LSize := c_size ? c_size : d_LSize
    } else if(Type(item) = "String" || Type(item) = "Integer") {
        LBuf := Buffer(StrPut(item, "UTF-8") - 1, 0)
        LItem := ""
        LSize := d_LSize
        temp_buf := Buffer(LBuf.size + 1, 0)
        StrPut(item, temp_buf, "UTF-8")
        copy_str()
    } else if(Type(item) = "Buffer") {
        LBuf := item
        LItem := ""
        LSize := d_LSize
    }

    if LBuf {
        hDigest := Buffer(o.%LType%.size)
        if _file {
            ; t := (_file.Length // LSize) + 1
            while(_file.Pos < _file.Length) {
                nRead := Min(LSize, _file.Length - _file.Pos)
                LBuf := Buffer(nRead, 0)
                nRead := _file.RawRead(LBuf) ; actual bytes, not the allocated size
                if !nRead
                    break
                if DllCall("bcrypt\BCryptHashData", "UPtr", o.%LType%.hHash
                    , "UPtr", LBuf.ptr, "UInt", nRead, "UInt", 0) != 0
                    throw Error("BCryptHashData failed.")
                if Type(cb) = "Func"
                    cb(_file.Pos / _file.Length)
            }
        } else {
            if DllCall("bcrypt\BCryptHashData", "UPtr", o.%LType%.hHash
                , "UPtr", LBuf.ptr, "UInt", LBuf.size, "UInt", 0) != 0
                throw Error("BCryptHashData failed.")
            if Type(cb) = "Func"
                cb(1)
        }
        if DllCall("bcrypt\BCryptFinishHash", "UPtr", o.%LType%.hHash
            , "UPtr", hDigest.ptr, "UInt", hDigest.size, "UInt", 0) != 0
            throw Error("BCryptFinishHash failed.")
        loop hDigest.size
            outVal .= Format("{:02X}", NumGet(hDigest, A_Index - 1, "UChar"))
    }

    _file ? (_file.Close(), LBuf := "") : ""
    return outVal

    make_obj() {
        if DllCall("bcrypt\BCryptOpenAlgorithmProvider", "UPtr*", &hAlg := 0
            , "Str", LType, "UPtr", 0, "UInt", 0x20) != 0 ; BCRYPT_HASH_REUSABLE_FLAG
            throw Error("BCryptOpenAlgorithmProvider failed.")
        if DllCall("bcrypt\BCryptGetProperty", "UPtr", hAlg, "Str", "ObjectLength"
            , "UInt*", &objSize := 0, "UInt", 4, "UInt*", &_size := 0, "UInt", 0) != 0
            throw Error("BCryptGetProperty ObjectLength failed.")
        if DllCall("bcrypt\BCryptGetProperty", "UPtr", hAlg, "Str", "HashDigestLength"
            , "UInt*", &hashSize := 0, "UInt", 4, "UInt*", &_size := 0, "UInt", 0) != 0
            throw Error("BCryptGetProperty HashDigestLength failed.")
        obj := Buffer(objSize)
        if DllCall("bcrypt\BCryptCreateHash", "UPtr", hAlg, "UPtr*", &hHash := 0
            , "UPtr", obj.ptr, "UInt", obj.size, "UPtr", 0, "UInt", 0, "UInt", 0x20) != 0
            throw Error("BCryptCreateHash failed.")
        o.%LType% := { obj: obj, hHash: hHash, hAlg: hAlg, size: hashSize }
    }

    graceful_exit(r1 := 0, r2 := 0) {
        for name, obj in o.OwnProps() {
            if o.%name%.hHash
                && (r1 := DllCall("bcrypt\BCryptDestroyHash", "UPtr", o.%name%.hHash)
                || r2 := DllCall("bcrypt\BCryptCloseAlgorithmProvider", "UPtr", o.%name%.hAlg, "UInt", 0))
                throw Error("Unable to destroy hash object.")
            o.%name%.hHash := o.%name%.hAlg := o.%name%.size := 0
            o.%name%.obj := ""
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
