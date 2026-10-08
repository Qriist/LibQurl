;This file contains the storage class that tells LibQurl where to put downloads
;***

class Storage {
    ; Wrapper for file. Shouldn't be used directly.

    class File {
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
            if(this.writeObj["accessMode"] == "w") {
                SplitPath(this.writeObj["filename"], , &fileDirPath)
                if fileDirPath
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
            return this.writeObj["writeTo"].Write(data)
        }

        RawWrite(srcDataPtr, srcDataSize) {
            ; If (this._fileObject == "")
            ; || (this._accessMode != "w")
            ; 	Return -1
            return this.writeObj["writeTo"].RawWrite(srcDataPtr + 0, srcDataSize)
        }

        getCurlHandle() {
            return this.writeObj["curlHandle"]
        }

        RawRead(dstDataPtr, dstDataSize) {
            ; 	If (this._fileObject == "")
            ; 	|| (this._accessMode != "r")
            ; 		Return -1

            return this.writeObj["writeTo"].RawRead(dstDataPtr + 0, dstDataSize)
        }

        Seek(offset, origin := 0) {
            return !(this.writeObj["writeTo"].Seek(offset, origin))
        }
    }

    class MemBuffer {
        ; Wrapper for memory buffer, similar to regular FileObject but less general purpose
        __New(easy_handle, inBuf, maxCapacity := 50 * 1024 ** 2, &easyHandleMap, storageCategory) {
            ;maxCapacity defaults to 50mb.

            this.easy_handle := easy_handle
            this.storageCategory := storageCategory
            this.easyHandleMap := easyHandleMap
            this.allocChunkSize := 50 * 1024 ** 2

            inBuf.offset := 0
            inBuf.maxCapacity := Max(maxCapacity, inBuf.Size)   ;prevent accidental truncation
            ; inBuf.trueSize := inBuf.size

            switch storageCategory {
                case "header", "body":
                    this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                    this.writeObj["writeTo"] := inBuf
                    this.writeObj["easy_handle"] := easy_handle
                    this.writeObj["writeType"] := "memory"

                case "read":
                    this.readObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                    this.readObj["readFrom"] := inBuf
                    this.readObj["easy_handle"] := easy_handle
            }

        }
        RawRead(dstDataPtr, dstDataSize) {
            sourceBuf := this.readObj["readFrom"]
            dataLeft := sourceBuf.Size - sourceBuf.offset
            if(dataLeft <= 0)
                return 0  ; EOF

            bytesToRead := dstDataSize < dataLeft ? dstDataSize : dataLeft

            DllCall("ntdll\memcpy"
                , "Ptr", dstDataPtr ;destination
                , "Ptr", sourceBuf.ptr + sourceBuf.offset   ;source
                , "UPtr", bytesToRead)  ;length

            sourceBuf.offset += bytesToRead
            return bytesToRead
        }
        RawWrite(srcDataPtr, srcDataSize) {
            destBuf := this.writeObj["writeTo"]

            ;allocation check
            requiredSize := destBuf.offset + srcDataSize
            if requiredSize > destBuf.size {
                destBuf.size := Ceil(requiredSize / this.allocChunkSize) * this.allocChunkSize
            }

            ; destBuf.size += srcDataSize    ;expand to accomodate incoming data
            DllCall("ntdll\memcpy"
                , "Ptr", destBuf.Ptr + destBuf.offset
                , "Ptr", srcDataPtr + 0
                , "Int", srcDataSize)
            destBuf.offset += srcDataSize
            ; destBuf.trueSize += srcDataSize
            return srcDataSize
        }
        Close() {
            ;truncates the buffer to the final output size
            destBuf := this.writeObj["writeTo"]
            destBuf.size := destBuf.offset
        }

    }
    class MemBuffer_old {
        ; Wrapper for memory buffer, similar to regular FileObject
        __New(dataPtr := 0, maxCapacity?, dataSize := 0, &handleMap?, storageCategory?, easy_handle?) {
            this._dataPos := 0
            this.easyHandleMap := handleMap
            easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle

            this.easy_handle := easy_handle
            this.storageCategory := storageCategory
            this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
            switch storageCategory {
                case "read":
                    this.writeObj["writeType"] := "memory-read"
                default:
                    this.writeObj["writeType"] := "memory"
            }

            ;give some starting space
            if !IsSet(maxCapacity) || (maxCapacity = 0)
                maxCapacity := 50 * 1024 ** 2  ; 50 Mb

            maxCapacity := Max(maxCapacity, dataSize)
            this.writeObj["maxCapacity"] := maxCapacity
            this.writeObj["writeTo"] := Buffer(0)
            this.ptr := this.writeObj["writeTo"].ptr

            ; msgbox "New " ObjPtr(this.writeObj["writeTo"])
            ; MsgBox maxCapacity "`n" this.writeObj["writeTo"].Ptr
            ; this.writeObj["writeTo"].Ptr := this.writeObj["writeTo"]
            ; this.writeObj["writeTo"] := Buffer(maxCapacity)
            this.writeObj["curlHandle"] := easy_handle
            this.writeObj["interimPtr"] := 0

            ; MsgBox strget(dataPtr, "UTF-8")

            if(dataPtr != 0) {
                this._dataMax := maxCapacity
                this._dataSize := dataSize
                this._dataPtr := dataPtr
                this.writeObj["readFrom"] := Buffer(this._dataSize, this._dataPtr)
                this.writeObj["postFile"] := Buffer(this._dataSize, this._dataPtr)

                MsgBox StrGet(this.writeObj["readFrom"].ptr, "UTF-8")
            } else
            ; No argument, store inside class.
            {
                this._dataSize := 0
                this._dataMax := ObjSetCapacity(this.writeObj["writeTo"], maxCapacity)
                this._dataPtr := 0 ;ObjGetAddress(this._data)
                ; msgbox this._dataMax
            }
        }

        Open(sourceBuffer?, bufferSize?) {
            ; Do nothing
        }

        Close() {
            this.writeObj["writeTo"].Size := this._dataSize ;truncates the buffer to the final output size
            ; this.easyHandleMap[this.easy_handle]["lastHeaders"] := this.writeObj["writeTo"]
            ; msgbox strget(this.writeObj["writeTo"],"UTF-8")
        }

        RawRead(dstDataPtr, dstDataSize) {
            dataLeft := this._dataSize - this._dataPos
            if(dataLeft <= 0)
                return 0  ; EOF
            ; msgbox this.printobj(this.writeObj)
            ; MsgBox StrGet(this.writeObj["readFrom"], "UTF-8")
            bytesToRead := dstDataSize < dataLeft ? dstDataSize : dataLeft

            DllCall("ntdll\memcpy"
                , "Ptr", dstDataPtr
                ; , "Ptr", this.writeObj["writeTo"].Ptr + this._dataPos
                , "Ptr", this._dataPtr + this._dataPos
                , "UPtr", bytesToRead)

            this._dataPos += bytesToRead
            return bytesToRead
        }
        RawWrite(srcDataPtr, srcDataSize) {
            Offset := this.writeObj["writeTo"].size ;use previous size to determine current offset
            this.writeObj["writeTo"].size += srcDataSize    ;expand to accomodate incoming data
            DllCall("ntdll\memcpy"
                , "Ptr", this.writeObj["writeTo"].Ptr + Offset
                , "Ptr", srcDataPtr + 0
                , "Int", srcDataSize)
            this._dataSize := this._dataPtr += srcDataSize
            return srcDataSize
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
            return this._dataSize
        }
    }

    class Magic {
        ; transparently merges MemBuffer and File modes for an ideal solution to temp files
        __New(easy_handle, flushFilename, flushThreshold := 50 * 1024 ** 2, &easyHandleMap, storageCategory) {
            this.easy_handle := easy_handle
            this.storageCategory := storageCategory
            this.easyHandleMap := easyHandleMap
            this.allocChunkSize := 50 * 1024 ** 2
            this.flushFilename := flushFilename

            flushThreshold := max(flushThreshold, 1024 ** 2) ;min 1mb
            this.flushThreshold := flushThreshold

            ;prepare initial buffer
            inBuf := Buffer(0)
            inBuf.offset := 0

            switch storageCategory {
                case "header", "body":
                    this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                    this.writeObj["writeTo"] := inBuf
                    this.writeObj["easy_handle"] := easy_handle
                    this.writeObj["writeType"] := "magic-memory"

                case "read":
                    this.readObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
                    this.readObj["readFrom"] := inBuf
                    this.readObj["easy_handle"] := easy_handle
            }
        }
        RawWrite(srcDataPtr, srcDataSize) {
            destObj := this.writeObj
            destBin := destObj["writeTo"]

            ;initial buffer conditions
            if(destObj["writeType"] = "magic-memory") {
                if(this.flushThreshold > (destBin.offset + srcDataSize)) {
                    ;allocation check
                    requiredSize := destBin.offset + srcDataSize
                    if requiredSize > destBin.size {
                        destBin.size := Ceil(requiredSize / this.allocChunkSize) * this.allocChunkSize
                    }

                    ; destBin.size += srcDataSize    ;expand to accomodate incoming data
                    DllCall("ntdll\memcpy"
                        , "Ptr", destBin.Ptr + destBin.offset
                        , "Ptr", srcDataPtr + 0
                        , "Int", srcDataSize)
                    destBin.offset += srcDataSize
                    ; destBuf.trueSize += srcDataSize
                    return srcDataSize
                }

                ;threshold met, perform one-time flush to disk

                destObj["writeType"] := "magic-file"
                destObj["filename"] := this.flushFilename
                this.flushFilename := unset
                SplitPath(destObj["filename"], , &fileDirPath)
                if fileDirPath
                    DirCreate fileDirPath
                tempObj := FileOpen(destObj["filename"], destObj["accessMode"] := "w", "CP0")

                flushBytes := destBin.offset
                tempObj.RawWrite(destObj["writeTo"], flushBytes)

                destObj["writeTo"] := tempObj
                destBin := destObj["writeTo"]
                destBin.offset := flushBytes

                ;don't return yet because the incoming data still needs to be written to file
            }

            ; this._dataSize := this._dataPtr += srcDataSize
            destBin.offset += srcDataSize
            return destBin.RawWrite(srcDataPtr + 0, srcDataSize)
        }

        Length() {
            return this._dataSize
        }
        Close() {
            if(this.writeObj["writeType"] = "magic-memory")
                this.writeObj["writeTo"].Size := this.writeObj["writeTo"].offset ;truncates the buffer to the final output size
            else ;magic-file
                this.writeObj["writeTo"].Close()
        }
    }

    class Magic_old {
        ; transparently merges MemBuffer and File modes for an ideal solution to temp files
        __New(easy_handle, flushFilename, flushThreshold := 50 * 1024 ** 2, &handleMap?, storageCategory?) {
            ;object begins life as a MemBuffer clone
            this._dataPos := 0
            this.easyHandleMap := handleMap
            easy_handle ??= this.easyHandleMap[0]["easy_handle"]   ;defaults to the last created easy_handle

            this.easy_handle := easy_handle
            this.storageCategory := storageCategory
            this.writeObj := this.easyHandleMap[easy_handle]["callbacks"][storageCategory]
            this.writeObj["writeType"] := "magic-memory"

            this.writeObj["flushThreshold"] := flushThreshold
            this.writeObj["flushFilename"] := flushFilename
            this.writeObj["writeTo"] := Buffer(0)

            this.writeObj["curlHandle"] := easy_handle
            this.writeObj["interimPtr"] := 0

            this._dataSize := 0
            this._dataMax := flushThreshold
            this._dataPtr := 0 ;ObjGetAddress(this._data)
        }

        Open() {
            ; Do nothing
        }

        Close() {
            if(this.writeObj["writeType"] = "magic-memory")
                this.writeObj["writeTo"].Size := this._dataSize ;truncates the buffer to the final output size
            else ;magic-file
                this.writeObj["writeTo"].Close()
        }

        RawWrite(srcDataPtr, srcDataSize) {
            ;initial buffer conditions
            if(this.writeObj["writeType"] = "magic-memory") {
                if(this.writeObj["flushThreshold"] > (this._dataSize + srcDataSize)) {
                    Offset := this.writeObj["writeTo"].size ;use previous size to determine current offset
                    this.writeObj["writeTo"].size += srcDataSize    ;expand to accomodate incoming data
                    DllCall("ntdll\memcpy"
                        , "Ptr", this.writeObj["writeTo"].Ptr + Offset
                        , "Ptr", srcDataPtr + 0
                        , "Int", srcDataSize)
                    this._dataSize := this._dataPtr += srcDataSize
                    return srcDataSize
                }

                ;threshold met, perform one-time flush to disk
                this.writeObj["writeType"] := "magic-file"
                this.writeObj["filename"] := this.writeObj["flushFilename"]
                this.writeObj["flushFilename"] := unset
                SplitPath(this.writeObj["filename"], , &fileDirPath)
                if fileDirPath
                    DirCreate fileDirPath
                tempObj := FileOpen(this.writeObj["filename"], this.writeObj["accessMode"] := "w", "CP0")
                tempObj.RawWrite(this.writeObj["writeTo"])
                this.writeObj["writeTo"] := tempObj

                ;don't return yet because the incoming data still needs to be written to file
            }

            this._dataSize := this._dataPtr += srcDataSize
            return this.writeObj["writeTo"].RawWrite(srcDataPtr + 0, srcDataSize)
        }

        Length() {
            return this._dataSize
        }
    }
}
