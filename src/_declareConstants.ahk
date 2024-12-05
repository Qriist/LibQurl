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

    this.constants["CURLINFO_offsets"] := c := Map()
    c.CaseSense := 0
    c["STRING"] := 0x100000
    c["LONG"] := 0x200000
    c["DOUBLE"] := 0x300000
    c["SLIST"] := 0x400000
    c["PTR"] := 0x400000    ;same as SLIST
    c["SOCKET"] := 0x500000
    c["OFF_T"] := 0x600000
    c["MASK"] := 0x0fffff
    c["TYPEMASK"] := 0xf00000

    this.constants["CURLINFO"] := c := Map()
    c.CaseSense := 0
    c["NONE"] := unset
    c["EFFECTIVE_URL"] := this.constants["CURLINFO_offsets"]["STRING"] + 1
    c["RESPONSE_CODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 2
    c["TOTAL_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 3
    c["NAMELOOKUP_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 4
    c["CONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 5
    c["PRETRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 6
    c["SIZE_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 7
    c["SIZE_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 8
    c["SPEED_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 9
    c["SPEED_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 10
    c["HEADER_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 11
    c["REQUEST_SIZE"] := this.constants["CURLINFO_offsets"]["LONG"] + 12
    c["SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 13
    c["FILETIME"] := this.constants["CURLINFO_offsets"]["LONG"] + 14
    c["FILETIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 14
    c["CONTENT_LENGTH_DOWNLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 15
    c["CONTENT_LENGTH_UPLOAD_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 16
    c["STARTTRANSFER_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 17
    c["CONTENT_TYPE"] := this.constants["CURLINFO_offsets"]["STRING"] + 18
    c["REDIRECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 19
    c["REDIRECT_COUNT"] := this.constants["CURLINFO_offsets"]["LONG"] + 20
    c["PRIVATE"] := this.constants["CURLINFO_offsets"]["STRING"] + 21
    c["HTTP_CONNECTCODE"] := this.constants["CURLINFO_offsets"]["LONG"] + 22
    c["HTTPAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 23
    c["PROXYAUTH_AVAIL"] := this.constants["CURLINFO_offsets"]["LONG"] + 24
    c["OS_ERRNO"] := this.constants["CURLINFO_offsets"]["LONG"] + 25
    c["NUM_CONNECTS"] := this.constants["CURLINFO_offsets"]["LONG"] + 26
    c["SSL_ENGINES"] := this.constants["CURLINFO_offsets"]["SLIST"] + 27
    c["COOKIELIST"] := this.constants["CURLINFO_offsets"]["SLIST"] + 28
    c["FTP_ENTRY_PATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 30
    c["REDIRECT_URL"] := this.constants["CURLINFO_offsets"]["STRING"] + 31
    c["PRIMARY_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 32
    c["APPCONNECT_TIME"] := this.constants["CURLINFO_offsets"]["DOUBLE"] + 33
    c["CERTINFO"] := this.constants["CURLINFO_offsets"]["PTR"] + 34
    c["CONDITION_UNMET"] := this.constants["CURLINFO_offsets"]["LONG"] + 35
    c["RTSP_SESSION_ID"] := this.constants["CURLINFO_offsets"]["STRING"] + 36
    c["RTSP_CLIENT_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 37
    c["RTSP_SERVER_CSEQ"] := this.constants["CURLINFO_offsets"]["LONG"] + 38
    c["RTSP_CSEQ_RECV"] := this.constants["CURLINFO_offsets"]["LONG"] + 39
    c["PRIMARY_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 40
    c["LOCAL_IP"] := this.constants["CURLINFO_offsets"]["STRING"] + 41
    c["LOCAL_PORT"] := this.constants["CURLINFO_offsets"]["LONG"] + 42
    c["ACTIVESOCKET"] := this.constants["CURLINFO_offsets"]["SOCKET"] + 44
    c["TLS_SSL_PTR"] := this.constants["CURLINFO_offsets"]["PTR"] + 45
    c["HTTP_VERSION"] := this.constants["CURLINFO_offsets"]["LONG"] + 46
    c["PROXY_SSL_VERIFYRESULT"] := this.constants["CURLINFO_offsets"]["LONG"] + 47
    c["SCHEME"] := this.constants["CURLINFO_offsets"]["STRING"] + 49
    c["TOTAL_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 50
    c["NAMELOOKUP_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 51
    c["CONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 52
    c["PRETRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 53
    c["STARTTRANSFER_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 54
    c["REDIRECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 55
    c["APPCONNECT_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 56
    c["RETRY_AFTER"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 57
    c["EFFECTIVE_METHOD"] := this.constants["CURLINFO_offsets"]["STRING"] + 58
    c["PROXY_ERROR"] := this.constants["CURLINFO_offsets"]["LONG"] + 59
    c["REFERER"] := this.constants["CURLINFO_offsets"]["STRING"] + 60
    c["CAINFO"] := this.constants["CURLINFO_offsets"]["STRING"] + 61
    c["CAPATH"] := this.constants["CURLINFO_offsets"]["STRING"] + 62
    c["XFER_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 63
    c["CONN_ID"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 64
    c["QUEUE_TIME_T"] := this.constants["CURLINFO_offsets"]["OFF_T"] + 65
    c["LASTONE"] := 65
}
