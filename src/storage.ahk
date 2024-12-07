;This file contains the storage class that tells LibQurl where to put downloads
;***

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
