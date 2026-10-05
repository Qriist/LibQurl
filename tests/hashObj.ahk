#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\packages.ahk
SetWorkingDir(A_ScriptDir "\..")

curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

; curl := LibQurl()
obj := {
    test01: "abc",
    test02: "xyz",
    test03: Map(
        "subtest1", "all",
        "subtest2", "good"
    ),
    test04: [
        "0",
        1,
        2 "3"
    ],
    test05: [
        Map(
            "dubsubtest1", "kk")
    ],
    test06: Buffer(10, 81),
    ; test07: FileOpen(A_ScriptDir "\test.txt", "r"),
    test08: true,
    test09: Null(),
    test10: "Null"
}

fmap := Map(
    "abc", FileOpen("C:\Projects\hashObj\lib\test1.txt", "r"),
    "xyz", FileOpen("C:\Projects\hashObj\lib\test2.txt", "r")
)

; class Null {

; }

; obj.test06.arbitraryProp1 := "hello world"
; obj.test07.arbitraryProp2 := "goodbye universe"

; ; MsgBox type(test)
; ; msgbox hash(&str, "md2")
; MsgBox a_clipboard := hashObj(obj, 1) "`n`n`n" hashObj(obj)
; MsgBox a_clipboard := hashObj(curl, "md2", , , , 1) "`n`n`n" hashObj(curl, "md2")
; loop 1000
; hashObj(curl)


; obj1 := {
;     name: "one"
; }

; obj2 := {
;     name: "two"
; }

; obj1.other := obj2
; obj2.other := obj1
; obj := {
;     name: "root",
;     child: {
;         name: "child"
;     },
;     map: Map(),
;     array: []
; }

; ; Direct self-reference
; obj.self := obj

; ; Mutual reference
; obj.child.parent := obj

; ; Shared reference
; obj.shared1 := obj.child
; obj.shared2 := obj.child

; ; Map containing references back into the graph
; obj.map["root"] := obj
; obj.map["child"] := obj.child
; obj.map["array"] := obj.array

; ; Array containing references back into the graph
; obj.array.Push(obj)
; obj.array.Push(obj.child)
; obj.array.Push(obj.map)

; ; Another object buried inside the Map
; obj.map["nested"] := {
;     name: "nested",
;     parent: obj.child
; }

; ; Close another loop:
; obj.map["nested"].root := obj

; ; And have the child point into the nested structure
; obj.child.nested := obj.map["nested"]

; MsgBox a_clipboard := hashObj(obj, 1) "`n`n`n" hashObj(obj, 2) "`n`n`n" hashObj(obj)

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
        return hash(&inObj, "SHA512")

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
                    hashObj(v, nohash, resultArr, ptrMap, 0)
                } else {
                    ; val := (!nohash ? hash(&v,) : v)
                    val := (!nohash ? hash(&v, "SHA512") : nohash = 1 ? v : hash(&v, "SHA512"))
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
                        hashObj(v, nohash, resultArr, ptrMap, 0)
                    } else
                        val := (!nohash ? hash(&v, "SHA512") : nohash = 1 ? v : hash(&v, "SHA512"))
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
                    val := (!nohash ? hash(&inObj, "SHA512") : nohash = 1 ? "[BUFFER]" : hash(&inObj, "SHA512"))
                    resultArr.Push("+" inobj.size ":|:" val "=")
                case "File":
                    hashfile := _GetFilePathFromFileObject(inObj)
                    hashfile := FileOpen(hashfile, "r")
                    val := (!nohash ? hash(&hashfile, "SHA512") : nohash = 1 ? "[FILE]" : hash(&inObj, "SHA512"))
                    resultArr.Push("+" hashfile.Length ":-:" val "=")
            }
            resultArr.Push(paraend)    ;object close
    }

    ; prevent finalizing
    if !top
        return ""

    ;export
    concat := ""
    VarSetStrCapacity(&concat, resultArr.Length * 128)
    for k, v in resultArr
        concat .= v
    VarSetStrCapacity(&concat, -1)

    if nohash
        return concat
    return hash(&concat, "SHA512")
    hash(&item := "", hashType := "", c_size := "", cb := "") { ; default hashType = SHA256 /// default enc = UTF-16
        static _hLib := DllCall("LoadLibrary", "Str", "bcrypt.dll", "UPtr"), LType := "SHA256", LItem := "", LBuf := "", LSize := "", d_LSize :=
            1024000
        static n := { hAlg: 0, hHash: 0, size: 0, obj: "" }
            , o := { md2: n.Clone(), md4: n.Clone(), md5: n.Clone(), sha1: n.Clone(), sha256: n.Clone(), sha384: n.Clone(), sha512: n.Clone() }
        _file := "", LType := (hashType ? StrUpper(hashType) : LType), LItem := (item ? item : LItem), ((!o.%LType%.hAlg) ? make_obj() : "")

        if (!item && !hashType) { ; Free buffers/memory and release objects.
            return !graceful_exit()
        } else if (Type(LItem) = "File") { ; Determine buffer type.
            _file := LItem, LBuf := true, LSize := (c_size ? c_size : d_LSize)
        } else if (Type(item) = "String") || (Type(item) = "Integer") {
            LBuf := Buffer(StrPut(item, "UTF-8") - 1, 0), LItem := "", LSize := d_LSize
            temp_buf := Buffer(LBuf.size + 1, 0), StrPut(item, temp_buf, "UTF-8"), copy_str()
        } else if (Type(item) = "Buffer")
            LBuf := item, LItem := "", LSize := d_LSize

        if (LBuf && !(outVal := "")) {
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
    _GetFilePathFromFileObject(FileObject) {
        static GetFinalPathNameByHandleW := DllCall("Kernel32\GetProcAddress", "Ptr", DllCall("Kernel32\GetModuleHandle",
            "Str", "Kernel32", "Ptr"), "AStr", "GetFinalPathNameByHandleW", "Ptr")

        ; if !FileObject
        ; throw Error("Invalid file handle")

        ; Initialize a buffer to receive the file path
        static bufSize := 65536    ;64kb to accomodate long path names in UTF-16
        buf := Buffer(bufSize)

        ; Call GetFinalPathNameByHandleW
        len := DllCall(GetFinalPathNameByHandleW
            , "Ptr", FileObject.handle       ; File handle
            , "Ptr", buf         ; Buffer to receive the path
            , "UInt", bufSize    ; Size of the buffer (in wchar_t units)
            , "UInt", 0          ; Flags (0 for default behavior)
            , "UInt")            ; Return length of the file path

        if (len == 0 || len > bufSize)
            throw Error("Failed to retrieve file path or insufficient buffer size", A_LastError)

        ; Return the result as a string
        return StrGet(buf, "UTF-16")
    }
}