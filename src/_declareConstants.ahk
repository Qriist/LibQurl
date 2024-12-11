;This file contains, you guessed it, constants.
;***
_declareConstants(){
    ;local function for preparing constants which depend on offsets
    bindOffsets(offsetGroup,offsetOrdinal,offsetType){
        ret := this._DeepClone(this.constants[offsetGroup][offsetType])
        ret["id"] := ret["offset"] + offsetOrdinal
        ret.delete("offset")
        return ret
    }
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
    o["SLIST"] := Map("offset",0x400000,"infoType","SLIST","dllType","Ptr*")    ;good, probably
    o["PTR"] := Map("offset",0x400000,"infoType","PTR","dllType","Ptr*")    ;good, probably
    o["SOCKET"] := Map("offset",0x500000,"infoType","SOCKET","dllType","Ptr*")  ;good, probably
    o["OFF_T"] := Map("offset",0x600000,"infoType","OFF_T","dllType","Ptr*")    ;good
    o["MASK"] := Map("offset",0x0fffff,"infoType","MASK","dllType","UInt*") ;unused?
    o["TYPEMASK"] := Map("offset",0xf00000,"infoType","TYPEMASK","dllType","UInt*") ;unused?

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
    c["TLS_SESSION"] :=                 bindOffsets(offsetGroup, 43, "PTR")
    c["ACTIVESOCKET"] :=                bindOffsets(offsetGroup, 44, "SOCKET")
    c["TLS_SSL_PTR"] :=                 bindOffsets(offsetGroup, 45, "PTR")
    c["HTTP_VERSION"] :=                bindOffsets(offsetGroup, 46, "LONG")
    c["PROXY_SSL_VERIFYRESULT"] :=      bindOffsets(offsetGroup, 47, "LONG")
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

    this.constants["CURLH_ORIGINS"] := c := Map()
    c.CaseSense := 0
    c["HEADER"] := (1<<0)
    c["TRAILER"] := (1<<1)
    c["CONNECT"] := (1<<2)
    c["1XX"] := (1<<3)
    c["PSUEDO"] := (1<<4)
    
    this.constants["curl_sslbackend"] := c := Map()
    c.CaseSense := 0
    c["NONE"] := 0
    c["OPENSSL"] := 1
    c["GNUTLS"] := 2
    c["WOLFSSL"] := 7
    c["SCHANNEL"] := 8
    c["SECURETRANSPORT"] := 9
    c["MBEDTLS"] := 11
    c["BEARSSL"] := 13
    c["RUSTLS"] := 14

    ; todo with the error handlers
    ; this.constants["CURLHcode"] := c := Map()  
    ; typedef enum {
    ;     CURLHE_OK,
    ;     CURLHE_BADINDEX,      /* header exists but not with this index */
    ;     CURLHE_MISSING,       /* no such header exists */
    ;     CURLHE_NOHEADERS,     /* no headers at all exist (yet) */
    ;     CURLHE_NOREQUEST,     /* no request with this number was used */
    ;     CURLHE_OUT_OF_MEMORY, /* out of memory while processing */
    ;     CURLHE_BAD_ARGUMENT,  /* a function argument was not okay */
    ;     CURLHE_NOT_BUILT_IN   /* if API was disabled in the build */
    ;   } CURLHcode;

}