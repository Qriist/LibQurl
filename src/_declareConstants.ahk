;This file contains, you guessed it, constants.
;***
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

    this.constants["CURLINFO_offsets"] := o := Map()   
    o.CaseSense := 0
    o["STRING"] := Map("offset",0x100000,"infoType","STRING","dllType","Ptr*")  ;good
    o["LONG"] := Map("offset",0x200000,"infoType","LONG","dllType","Int*")  ;good
    o["DOUBLE"] := Map("offset",0x300000,"infoType","DOUBLE","dllType","Double*")   ;good
    o["SLIST"] := Map("offset",0x400000,"infoType","SLIST","dllType","Ptr*")
    o["PTR"] := Map("offset",0x400000,"infoType","PTR","dllType","Ptr*")
    o["SOCKET"] := Map("offset",0x500000,"infoType","SOCKET","dllType","Ptr*")
    o["OFF_T"] := Map("offset",0x600000,"infoType","OFF_T","dllType","Ptr*")    ;good
    o["MASK"] := Map("offset",0x0fffff,"infoType","MASK","dllType","Ptr*")
    o["TYPEMASK"] := Map("offset",0xf00000,"infoType","TYPEMASK","dllType","Ptr*")

    offsetGroup := "CURLINFO_offsets"    
    this.constants["CURLINFO"] := c := Map()
    c.CaseSense := 0
    c["EFFECTIVE_URL"] :=               bindOffsets(offsetGroup, 1, "STRING")
    c["RESPONSE_CODE"] :=               bindOffsets(offsetGroup, 2, "LONG")
    c["TOTAL_TIME"] :=                  bindOffsets(offsetGroup, 3, "DOUBLE")
    c["NAMELOOKUP_TIME"] :=             bindOffsets(offsetGroup, 4, "DOUBLE")
    c["CONNECT_TIME"] :=                bindOffsets(offsetGroup, 5, "DOUBLE")
    c["PRETRANSFER_TIME"] :=            bindOffsets(offsetGroup, 6, "DOUBLE")
    c["SIZE_UPLOAD_T"] :=               bindOffsets(offsetGroup, 7, "OFF_T")
    c["SIZE_DOWNLOAD_T"] :=             bindOffsets(offsetGroup, 8, "OFF_T")
    c["SPEED_DOWNLOAD_T"] :=            bindOffsets(offsetGroup, 9, "OFF_T")
    c["SPEED_UPLOAD_T"] :=              bindOffsets(offsetGroup, 10, "OFF_T")
    c["HEADER_SIZE"] :=                 bindOffsets(offsetGroup, 11, "LONG")
    c["REQUEST_SIZE"] :=                bindOffsets(offsetGroup, 12, "LONG")
    c["SSL_VERIFYRESULT"] :=            bindOffsets(offsetGroup, 13, "LONG")
    c["FILETIME"] :=                    bindOffsets(offsetGroup, 14, "LONG")
    c["FILETIME_T"] :=                  bindOffsets(offsetGroup, 14, "OFF_T")
    c["CONTENT_LENGTH_DOWNLOAD_T"] :=   bindOffsets(offsetGroup, 15, "OFF_T")
    c["CONTENT_LENGTH_UPLOAD_T"] :=     bindOffsets(offsetGroup, 16, "OFF_T")
    c["STARTTRANSFER_TIME"] :=          bindOffsets(offsetGroup, 17, "DOUBLE")
    c["CONTENT_TYPE"] :=                bindOffsets(offsetGroup, 18, "STRING")
    c["REDIRECT_TIME"] :=               bindOffsets(offsetGroup, 19, "DOUBLE")
    c["REDIRECT_COUNT"] :=              bindOffsets(offsetGroup, 20, "LONG")
    c["PRIVATE"] :=                     bindOffsets(offsetGroup, 21, "STRING")
    c["HTTP_CONNECTCODE"] :=            bindOffsets(offsetGroup, 22, "LONG")
    c["HTTPAUTH_AVAIL"] :=              bindOffsets(offsetGroup, 23, "LONG")
    c["PROXYAUTH_AVAIL"] :=             bindOffsets(offsetGroup, 24, "LONG")
    c["OS_ERRNO"] :=                    bindOffsets(offsetGroup, 25, "LONG")
    c["NUM_CONNECTS"] :=                bindOffsets(offsetGroup, 26, "LONG")
    c["SSL_ENGINES"] :=                 bindOffsets(offsetGroup, 27, "SLIST")
    c["COOKIELIST"] :=                  bindOffsets(offsetGroup, 28, "SLIST")
    c["FTP_ENTRY_PATH"] :=              bindOffsets(offsetGroup, 30, "STRING")
    c["REDIRECT_URL"] :=                bindOffsets(offsetGroup, 31, "STRING")
    c["PRIMARY_IP"] :=                  bindOffsets(offsetGroup, 32, "STRING")
    c["APPCONNECT_TIME"] :=             bindOffsets(offsetGroup, 33, "DOUBLE")
    c["CERTINFO"] :=                    bindOffsets(offsetGroup, 34, "PTR")
    c["CONDITION_UNMET"] :=             bindOffsets(offsetGroup, 35, "LONG")
    c["RTSP_SESSION_ID"] :=             bindOffsets(offsetGroup, 36, "STRING")
    c["RTSP_CLIENT_CSEQ"] :=            bindOffsets(offsetGroup, 37, "LONG")
    c["RTSP_SERVER_CSEQ"] :=            bindOffsets(offsetGroup, 38, "LONG")
    c["RTSP_CSEQ_RECV"] :=              bindOffsets(offsetGroup, 39, "LONG")
    c["PRIMARY_PORT"] :=                bindOffsets(offsetGroup, 40, "LONG")
    c["LOCAL_IP"] :=                    bindOffsets(offsetGroup, 41, "STRING")
    c["LOCAL_PORT"] :=                  bindOffsets(offsetGroup, 42, "LONG")
    c["ACTIVESOCKET"] :=                bindOffsets(offsetGroup, 44, "SOCKET")
    c["TLS_SSL_PTR"] :=                 bindOffsets(offsetGroup, 45, "PTR")
    c["HTTP_VERSION"] :=                bindOffsets(offsetGroup, 46, "LONG")
    c["PROXY_SSL_VERIFYRESULT"] :=  bindOffsets(offsetGroup, 47, "LONG")
    c["SCHEME"] :=                      bindOffsets(offsetGroup, 49, "STRING")
    c["TOTAL_TIME_T"] :=                bindOffsets(offsetGroup, 50, "OFF_T")
    c["NAMELOOKUP_TIME_T"] :=           bindOffsets(offsetGroup, 51, "OFF_T")
    c["CONNECT_TIME_T"] :=              bindOffsets(offsetGroup, 52, "OFF_T")
    c["PRETRANSFER_TIME_T"] :=          bindOffsets(offsetGroup, 53, "OFF_T")
    c["STARTTRANSFER_TIME_T"] :=        bindOffsets(offsetGroup, 54, "OFF_T")
    c["REDIRECT_TIME_T"] :=             bindOffsets(offsetGroup, 55, "OFF_T")
    c["APPCONNECT_TIME_T"] :=           bindOffsets(offsetGroup, 56, "OFF_T")
    c["RETRY_AFTER"] :=                 bindOffsets(offsetGroup, 57, "OFF_T")
    c["EFFECTIVE_METHOD"] :=            bindOffsets(offsetGroup, 58, "STRING")
    c["PROXY_ERROR"] :=                 bindOffsets(offsetGroup, 59, "LONG")
    c["REFERER"] :=                     bindOffsets(offsetGroup, 60, "STRING")
    c["CAINFO"] :=                      bindOffsets(offsetGroup, 61, "STRING")
    c["CAPATH"] :=                      bindOffsets(offsetGroup, 62, "STRING")
    c["XFER_ID"] :=                     bindOffsets(offsetGroup, 63, "OFF_T")
    c["CONN_ID"] :=                     bindOffsets(offsetGroup, 64, "OFF_T")
    c["QUEUE_TIME_T"] :=                bindOffsets(offsetGroup, 65, "OFF_T")
    c["LASTONE"] :=                     bindOffsets(offsetGroup, 65, "OFF_T")


    /*
    c["NONE"] := unset  ;just here for parity with the source
    ; c["EFFECTIVE_URL"] := bindOffsets(c,o,g,"STRING")
    c["EFFECTIVE_URL"] := Map("id", o["STRING"] + 1, "infoType", "STRING", "dllType", "Ptr*")
    c["RESPONSE_CODE"] := Map("id", o["LONG"] + 2, "infoType", "LONG", "dllType", "Int*")
    c["TOTAL_TIME"] := Map("id", o["DOUBLE"] + 3, "infoType", "DOUBLE", "dllType", "Ptr")
    c["NAMELOOKUP_TIME"] := Map("id", o["DOUBLE"] + 4, "infoType", "DOUBLE", "dllType", "Double*")
    c["CONNECT_TIME"] := Map("id", o["DOUBLE"] + 5, "infoType", "DOUBLE", "dllType", "Double*")
    c["PRETRANSFER_TIME"] := Map("id", o["DOUBLE"] + 6, "infoType", "DOUBLE", "dllType", "Double*")
    c["SIZE_UPLOAD"] := Map("id", o["DOUBLE"] + 7, "infoType", "DOUBLE", "dllType", "Double*")
    c["SIZE_UPLOAD_T"] := Map("id", o["OFF_T"] + 7, "infoType", "OFF_T", "dllType", "Int*")
    c["SIZE_DOWNLOAD"] := Map("id", o["DOUBLE"] + 8, "infoType", "DOUBLE", "dllType", "Double*")
    c["SIZE_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 8, "infoType", "OFF_T", "dllType", "Int*")
    c["SPEED_DOWNLOAD"] := Map("id", o["DOUBLE"] + 9, "infoType", "DOUBLE", "dllType", "Double*")
    c["SPEED_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 9, "infoType", "OFF_T", "dllType", "Int*")
    c["SPEED_UPLOAD"] := Map("id", o["DOUBLE"] + 10, "infoType", "DOUBLE", "dllType", "Double*")
    c["SPEED_UPLOAD_T"] := Map("id", o["OFF_T"] + 10, "infoType", "OFF_T", "dllType", "Int*")
    c["HEADER_SIZE"] := Map("id", o["LONG"] + 11, "infoType", "LONG", "dllType", "Int*")
    c["REQUEST_SIZE"] := Map("id", o["LONG"] + 12, "infoType", "LONG", "dllType", "Int*")
    c["SSL_VERIFYRESULT"] := Map("id", o["LONG"] + 13, "infoType", "LONG", "dllType", "Int*")
    c["FILETIME"] := Map("id", o["LONG"] + 14, "infoType", "LONG", "dllType", "Int*")
    c["FILETIME_T"] := Map("id", o["OFF_T"] + 14, "infoType", "OFF_T", "dllType", "Int*")
    c["CONTENT_LENGTH_DOWNLOAD"] := Map("id", o["DOUBLE"] + 15, "infoType", "DOUBLE", "dllType", "Double*")
    c["CONTENT_LENGTH_DOWNLOAD_T"] := Map("id", o["OFF_T"] + 15, "infoType", "OFF_T", "dllType", "Int*")
    c["CONTENT_LENGTH_UPLOAD"] := Map("id", o["DOUBLE"] + 16, "infoType", "DOUBLE", "dllType", "Double*")
    c["CONTENT_LENGTH_UPLOAD_T"] := Map("id", o["OFF_T"] + 16, "infoType", "OFF_T", "dllType", "Int*")
    c["STARTTRANSFER_TIME"] := Map("id", o["DOUBLE"] + 17, "infoType", "DOUBLE", "dllType", "Double*")
    c["CONTENT_TYPE"] := Map("id", o["STRING"] + 18, "infoType", "STRING", "dllType", "Ptr*")
    c["REDIRECT_TIME"] := Map("id", o["DOUBLE"] + 19, "infoType", "DOUBLE", "dllType", "Double*")
    c["REDIRECT_COUNT"] := Map("id", o["LONG"] + 20, "infoType", "LONG", "dllType", "Int*")
    c["PRIVATE"] := Map("id", o["STRING"] + 21, "infoType", "STRING", "dllType", "Ptr*")
    c["HTTP_CONNECTCODE"] := Map("id", o["LONG"] + 22, "infoType", "LONG", "dllType", "Int*")
    c["HTTPAUTH_AVAIL"] := Map("id", o["LONG"] + 23, "infoType", "LONG", "dllType", "Int*")
    c["PROXYAUTH_AVAIL"] := Map("id", o["LONG"] + 24, "infoType", "LONG", "dllType", "Int*")
    c["OS_ERRNO"] := Map("id", o["LONG"] + 25, "infoType", "LONG", "dllType", "Int*")
    c["NUM_CONNECTS"] := Map("id", o["LONG"] + 26, "infoType", "LONG", "dllType", "Int*")
    c["SSL_ENGINES"] := Map("id", o["SLIST"] + 27, "infoType", "SLIST", "dllType", "Ptr")
    c["COOKIELIST"] := Map("id", o["SLIST"] + 28, "infoType", "SLIST", "dllType", "Ptr")
    c["LASTSOCKET"] := Map("id", o["LONG"] + 29, "infoType", "LONG", "dllType", "Int*")
    c["FTP_ENTRY_PATH"] := Map("id", o["STRING"] + 30, "infoType", "STRING", "dllType", "Ptr*")
    c["REDIRECT_URL"] := Map("id", o["STRING"] + 31, "infoType", "STRING", "dllType", "Ptr*")
    c["PRIMARY_IP"] := Map("id", o["STRING"] + 32, "infoType", "STRING", "dllType", "Ptr*")
    c["APPCONNECT_TIME"] := Map("id", o["DOUBLE"] + 33, "infoType", "DOUBLE", "dllType", "Double*")
    c["CERTINFO"] := Map("id", o["PTR"] + 34, "infoType", "PTR", "dllType", "Ptr")
    c["CONDITION_UNMET"] := Map("id", o["LONG"] + 35, "infoType", "LONG", "dllType", "Int*")
    c["RTSP_SESSION_ID"] := Map("id", o["STRING"] + 36, "infoType", "STRING", "dllType", "Ptr*")
    c["RTSP_CLIENT_CSEQ"] := Map("id", o["LONG"] + 37, "infoType", "LONG", "dllType", "Int*")
    c["RTSP_SERVER_CSEQ"] := Map("id", o["LONG"] + 38, "infoType", "LONG", "dllType", "Int*")
    c["RTSP_CSEQ_RECV"] := Map("id", o["LONG"] + 39, "infoType", "LONG", "dllType", "Int*")
    c["PRIMARY_PORT"] := Map("id", o["LONG"] + 40, "infoType", "LONG", "dllType", "Int*")
    c["LOCAL_IP"] := Map("id", o["STRING"] + 41, "infoType", "STRING", "dllType", "Ptr*")
    c["LOCAL_PORT"] := Map("id", o["LONG"] + 42, "infoType", "LONG", "dllType", "Int*")
    c["TLS_SESSION"] := Map("id", o["PTR"] + 43, "infoType", "PTR", "dllType", "Ptr")
    c["ACTIVESOCKET"] := Map("id", o["SOCKET"] + 44, "infoType", "SOCKET", "dllType", "Ptr")
    c["TLS_SSL_PTR"] := Map("id", o["PTR"] + 45, "infoType", "PTR", "dllType", "Ptr")
    c["HTTP_VERSION"] := Map("id", o["LONG"] + 46, "infoType", "LONG", "dllType", "Int*")
    c["PROXY_SSL_VERIFYRESULT"] := Map("id", o["LONG"] + 47, "infoType", "LONG", "dllType", "Int*")
    c["PROTOCOL"] := Map("id", o["LONG"] + 48, "infoType", "LONG", "dllType", "Int*")
    c["SCHEME"] := Map("id", o["STRING"] + 49, "infoType", "STRING", "dllType", "Ptr*")
    c["TOTAL_TIME_T"] := Map("id", o["OFF_T"] + 50, "infoType", "OFF_T", "dllType", "Int*")
    c["NAMELOOKUP_TIME_T"] := Map("id", o["OFF_T"] + 51, "infoType", "OFF_T", "dllType", "Int*")
    c["CONNECT_TIME_T"] := Map("id", o["OFF_T"] + 52, "infoType", "OFF_T", "dllType", "Int*")
    c["PRETRANSFER_TIME_T"] := Map("id", o["OFF_T"] + 53, "infoType", "OFF_T", "dllType", "Int*")
    c["STARTTRANSFER_TIME_T"] := Map("id", o["OFF_T"] + 54, "infoType", "OFF_T", "dllType", "Int*")
    c["REDIRECT_TIME_T"] := Map("id", o["OFF_T"] + 55, "infoType", "OFF_T", "dllType", "Int*")
    c["APPCONNECT_TIME_T"] := Map("id", o["OFF_T"] + 56, "infoType", "OFF_T", "dllType", "Int*")
    c["RETRY_AFTER"] := Map("id", o["OFF_T"] + 57, "infoType", "OFF_T", "dllType", "Int64")
    c["EFFECTIVE_METHOD"] := Map("id", o["STRING"] + 58, "infoType", "STRING", "dllType", "Ptr*")
    c["PROXY_ERROR"] := Map("id", o["LONG"] + 59, "infoType", "LONG", "dllType", "Int*")
    c["REFERER"] := Map("id", o["STRING"] + 60, "infoType", "STRING", "dllType", "Ptr*")
    c["CAINFO"] := Map("id", o["STRING"] + 61, "infoType", "STRING", "dllType", "Ptr*")
    c["CAPATH"] := Map("id", o["STRING"] + 62, "infoType", "STRING", "dllType", "Ptr*")
    c["XFER_ID"] := Map("id", o["OFF_T"] + 63, "infoType", "OFF_T", "dllType", "Int64")
    c["CONN_ID"] := Map("id", o["OFF_T"] + 64, "infoType", "OFF_T", "dllType", "Int64")
    c["QUEUE_TIME_T"] := Map("id", o["OFF_T"] + 65, "infoType", "OFF_T", "dllType", "Int64")
    c["LASTONE"] := Map("id", 65, "infoType", "INVALID", "dllType", "None")
*/
        bindOffsets(offsetGroup,offsetOrdinal,offsetType){
        ret := this._DeepClone(this.constants[offsetGroup][offsetType])
        ret["id"] := ret["offset"] + offsetOrdinal
        ret.delete("offset")
        return ret
    }
    ; bindOffsets(v,o,g,type){
    ;     switch g {
    ;         case "CURLINFO": 
    ;             switch type {
    ;                 case "STRING":
    ;                     return Map(id,o[type]+v,"infoType",type,"dllType","Ptr*")
    ;                 case "LONG":
    ;                 case "DOUBLE":
    ;                 case "SLIST":
    ;                 case "PTR":
    ;                 case "SOCKET":
    ;                 case "OFF_T":
    ;                 case "MASK":
    ;                 case "TYPEMASK":
                                            
    ;             }
    ;     }
    ; }
    ; this.constants["CURLINFO"] := c := Map()
    ; c.CaseSense := 0
    ; c["NONE"] :=  

    ; c["EFFECTIVE_URL"] := o["STRING"] + 1
    
    ; c["EFFECTIVE_URL"] := Map("id",o["STRING"] + 1,"infoType","STRING","dllType","Ptr*")
    ; c["RESPONSE_CODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 2
    ; c["TOTAL_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 3
    ; c["NAMELOOKUP_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 4
    ; c["CONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 5
    ; c["PRETRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 6
    ; c["SIZE_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 7
    ; c["SIZE_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 8
    ; c["SPEED_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 9
    ; c["SPEED_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 10
    ; c["HEADER_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 11
    ; c["REQUEST_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 12
    ; c["SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 13
    ; c["FILETIME"] := this.constants["CURLINFO_offsets"]["LONG"] + 14
    ; c["FILETIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 14
    ; c["CONTENT_LENGTH_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 15
    ; c["CONTENT_LENGTH_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 16
    ; c["STARTTRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 17
    ; c["CONTENT_TYPE"] := this.constants["CURLINFO_offsets"]["STRING"] + 18
    ; c["REDIRECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 19
    ; c["REDIRECT_COUNT"] := this.constants["CURLINFO_offsets"]["LONG"] + 20
    ; c["PRIVATE"] := this.constants["CURLINFO_offsets"]["STRING"] + 21
    ; c["HTTP_CONNECTCODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 22
    ; c["HTTPAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 23
    ; c["PROXYAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 24
    ; c["OS_ERRNO"] := this.constants["CURLINFO_offsets"]["LONG"] + 25
    ; c["NUM_CONNECTS"] := this.constants["CURLINFO_offsets"]["LONG"] + 26
    ; c["SSL_ENGINES"] := this.constants["CURLINFO_offsets"]["SLIST"] + 27
    ; c["COOKIELIST"] := this.constants["CURLINFO_offsets"]["SLIST"] + 28
    ; c["FTP_ENTRY_PATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 30
    ; c["REDIRECT_URL"] := this.constants["CURLINFO_offsets"]["STRING"] + 31
    ; c["PRIMARY_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 32
    ; c["APPCONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 33
    ; c["CERTINFO"] := this.constants["CURLINFO_offsets"]["PTR"] + 34
    ; c["CONDITION_UNMET"] := this.constants["CURLINFO_offsets"]["LONG"] + 35
    ; c["RTSP_SESSION_ID"] := this.constants["CURLINFO_offsets"]["STRING"] + 36
    ; c["RTSP_CLIENT_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 37
    ; c["RTSP_SERVER_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 38
    ; c["RTSP_CSEQ_RECV"] := this.constants["CURLINFO_offsets"]["LONG"] + 39
    ; c["PRIMARY_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 40
    ; c["LOCAL_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 41
    ; c["LOCAL_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 42
    ; c["ACTIVESOCKET"] := this.constants["CURLINFO_offsets"]["SOCKET"] + 44
    ; c["TLS_SSL_PTR"] := this.constants["CURLINFO_offsets"]["PTR"] + 45
    ; c["HTTP_VERSION"] := this.constants["CURLINFO_offsets"]["LONG"] + 46
    ; c["PROXY_SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 47
    ; c["SCHEME"] := this.constants["CURLINFO_offsets"]["STRING"] + 49
    ; c["TOTAL_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 50
    ; c["NAMELOOKUP_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 51
    ; c["CONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 52
    ; c["PRETRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 53
    ; c["STARTTRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 54
    ; c["REDIRECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 55
    ; c["APPCONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 56
    ; c["RETRY_AFTER"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 57
    ; c["EFFECTIVE_METHOD"] := this.constants["CURLINFO_offsets"]["STRING"] + 58
    ; c["PROXY_ERROR"] := this.constants["CURLINFO_offsets"]["LONG"] + 59
    ; c["REFERER"] := this.constants["CURLINFO_offsets"]["STRING"] + 60
    ; c["CAINFO"] := this.constants["CURLINFO_offsets"]["STRING"] + 61
    ; c["CAPATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 62
    ; c["XFER_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 63
    ; c["CONN_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 64
    ; c["QUEUE_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 65
    ; c["LASTONE"] := 65
}