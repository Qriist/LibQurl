;This file contains a parsing class for the different libcurl structs
;***
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
        retObj["age"] := NumGet(ptr,(Offset := 0),"Int") + 1 ;intentionally +1
        retObj["version"] := StrGet(NumGet(ptr,8,"Ptr"),"UTF-8")
        retObj["version_num"] := NumGet(ptr,16,"UInt")
        retObj["host"] := StrGet(NumGet(ptr,24,"Ptr"),"UTF-8")
        retObj["features"] := NumGet(ptr,32,"UInt")
        retObj["ssl_version"] := StrGet(NumGet(ptr,40,"Ptr"),"UTF-8")
        retObj["ssl_version_num"] := NumGet(ptr,48,"UInt")
        retObj["libz_version"] := StrGet(NumGet(ptr,56,"Ptr"),"UTF-8")
        retObj["protocols"] := this.walkPtrArray(NumGet(ptr,64,"Ptr"))

        ;walk through optional struct members
        If (retObj["age"] >= 2) {
            retObj["ares"] := str(ptr,72)
            retObj["ares"] := NumGet(ptr,80,"Int")
        }
        If (retObj["age"] >= 3) {
            retObj["libidn"] := str(ptr,88)
        }
        If (retObj["age"] >= 4) {
            retObj["iconv_ver_num"] := NumGet(ptr, 96, "Int")
            retObj["libssh_version"] := str(ptr,104)
        }
        If (retObj["age"] >= 5) {
            retObj["brotli_ver_num"] := NumGet(ptr, 112, "Int")
            retObj["brotli_version"] := str(ptr, 120)
        }
        If (retObj["age"] >= 6) {
            retObj["nghttp2_version"] := NumGet(ptr, 128, "UInt")
            retObj["nghttp2"] := str(ptr,136)
            retObj["quic_version"] := str(ptr,144)
        }
        If (retObj["age"] >= 7) {
            retObj["cainfo"] := str(ptr,152)
            retObj["capath"] := str(ptr,160)   
        }
        If (retObj["age"] >= 8) {
            retObj["zstd_ver_num"] := NumGet(ptr,168,"Int")
            retObj["zstd_version"] := str(ptr,176)
        }
        If (retObj["age"] >= 9) {
            retObj["hyper_version"] := str(ptr,184)
        }
        If (retObj["age"] >= 10) {
            retObj["gsasl_version"] := str(ptr,192)
        }
        If (retObj["age"] >= 11) {
            retObj["feature_names"] := this.walkPtrArray(NumGet(ptr,200,"Ptr"))
        }
        return retObj
        str(ptr,offset,encoding := "UTF-8"){
            return (NumGet(ptr,offset,"Ptr")=0?0:StrGet(NumGet(ptr,offset,"Ptr"),encoding))
        }
    }
    curl_CURLMsg(ptr){
        retObj := Map()
        retObj["msg"] := NumGet(ptr,0,"UInt")
        retObj["easy_handle"] := NumGet(ptr,8,"Ptr")
        retObj["result"] := NumGet(ptr,12,"Int")
        ; msgbox ""
        ;     .   "msg: " retObj["msg"] "`n"
        ;     .   "easy_handle: " retObj["easy_handle"] "`n"
        ;     .   "result: " retObj["result"] "`n"
            return retObj
    }
    curl_header(ptr){
        retObj := Map()
        retObj["name"] := str(ptr,0)
        retObj["value"] := str(ptr,8)
        retObj["amount"] := NumGet(ptr,16,"UInt")
        retObj["index"] := NumGet(ptr,24,"UInt")
        retObj["origin"] := NumGet(ptr,24,"UInt")
        return retObj
        str(ptr,offset,encoding := "UTF-8"){
            return (NumGet(ptr,offset,"Ptr")=0?0:StrGet(NumGet(ptr,offset,"Ptr"),encoding))
        }
    }
}