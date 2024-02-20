class class_libcurl {
    hCURL := Map()
    static curlDLLhandle := ""
    static curlDLLpath := ""
    register(dllPath := "") {
        if !FileExist(dllPath)
            throw ValueError("libcurl DLL not found!", -1, dllPath)
        this.curlDLLpath := dllpath
        this.curlDLLhandle := DllCall("LoadLibrary", "Str", dllPath, "Ptr")   ;load the DLL into resident memory

        this._curl_global_init()

        return 1
    }


    ;internal libcurl functions called by this class
    _curl_easy_cleanup() {

    }
    _curl_easy_duphandle() {

    }
    _curl_easy_escape() {

    }
    _curl_easy_getinfo() {

    }
    _curl_easy_header() {

    }
    _curl_easy_init() {
        newHandle := DllCall(this.curlDLLpath "\curl_easy_init")
        this.hCURL[newHandle] := Map()
        this.hCURL[newHandle]["handle"] := newHandle
        If !this.hCURL[newHandle]
            throw ValueError("Problem in 'curl_easy_init'! Unable to init easy interface!", -1, this.curlDLLpath)
        return newHandle
    }
    _curl_easy_nextheader() {

    }
    _curl_easy_option_by_id() {

    }
    _curl_easy_option_by_name() {

    }
    _curl_easy_option_next() {

    }
    _curl_easy_pause() {

    }
    _curl_easy_perform() {

    }
    _curl_easy_recv() {

    }
    _curl_easy_reset(handle) {
        DllCall(this.curlDLLpath "\curl_easy_reset"
            ,"Ptr",this.hCURL[handle]["handle"])
    }
    _curl_easy_send() {

    }
    _curl_easy_setopt(handle,option,parameter) {
        DllCall(this.curlDLLpath "\curl_easy_setopt"
            ,"Ptr",this.hCURL[handle]["handle"]
            ,"Str",option
            ,"Str",parameter)
        return 
    }
    _curl_easy_strerror() {

    }
    _curl_easy_unescape() {

    }
    _curl_easy_upkeep() {

    }
    _curl_formadd() {

    }
    _curl_formfree() {

    }
    _curl_formget() {

    }
    _curl_free() {

    }
    _curl_getdate() {

    }
    _curl_global_cleanup() {

    }
    _curl_global_init() {
        /* https://curl.se/libcurl/c/curl_global_init.html
            curl_global_init - Global libcurl initialization
        
            CURLcode curl_global_init(long flags);
        
            Description
                - This function sets up the program environment that libcurl needs. Think of it as an extension of the library loader.
                - This function must be called at least once within a program (a program is all the code that shares a memory space) before the program calls any other function in libcurl. The environment it sets up is constant for the life of the program and is the same for every program, so multiple calls have the same effect as one call.
                - The flags option is a bit pattern that tells libcurl exactly what features to init, as described below. Set the desired bits by ORing the values together. In normal operation, you must specify CURL_GLOBAL_ALL. Do not use any other value unless you are familiar with it and mean to control internal operations of libcurl.
                - This function is thread-safe since libcurl 7.84.0 if curl_version_info has the CURL_VERSION_THREADSAFE feature bit set (most platforms).
                - If this is not thread-safe, you must not call this function when any other thread in the program (i.e. a thread sharing the same memory) is running. This does not just mean no other thread that is using libcurl. Because curl_global_init calls functions of other libraries that are similarly thread unsafe, it could conflict with any other thread that uses these other libraries.
                - If you are initializing libcurl from a Windows DLL you should not initialize it from DllMain or a static initializer because Windows holds the loader lock during that time and it could cause a deadlock.
                - See the description in libcurl of global environment requirements for details of how to use this function.
        
            Flags
                CURL_GLOBAL_ALL
                    - Initialize everything possible. This sets all known bits except CURL_GLOBAL_ACK_EINTR.
                CURL_GLOBAL_SSL
                    - (This flag's presence or absence serves no meaning since 7.57.0. The description below is for older libcurl versions.)
                    - Initialize SSL.
                    - The implication here is that if this bit is not set, the initialization of the SSL layer needs to be done by the application or at least outside of libcurl. The exact procedure how to do SSL initialization depends on the TLS backend libcurl uses.
                    - Doing TLS based transfers without having the TLS layer initialized may lead to unexpected behaviors.
                CURL_GLOBAL_WIN32
                    - Initialize the Win32 socket libraries.
                    - The implication here is that if this bit is not set, the initialization of winsock has to be done by the application or you risk getting undefined behaviors. This option exists for when the initialization is handled outside of libcurl so there's no need for libcurl to do it again.
                CURL_GLOBAL_NOTHING
                    - Initialize nothing extra. This sets no bit.
                CURL_GLOBAL_DEFAULT
                    - A sensible default. It will init both SSL and Win32. Right now, this equals the functionality of the CURL_GLOBAL_ALL mask.
                CURL_GLOBAL_ACK_EINTR
                    - This bit has no point since 7.69.0 but its behavior is instead the default.
        
            Before 7.69.0: when this flag is set, curl will acknowledge EINTR condition when connecting or when waiting for data. Otherwise, curl waits until full timeout elapses. (Added in 7.30.0)
        
            Example
                curl_global_init(CURL_GLOBAL_DEFAULT);
                * use libcurl, then before exiting... *
                curl_global_cleanup();
        
            Availability
                Added in 7.8
        
            Return value
                If this function returns non - zero, something went wrong and you cannot use the other curl functions.
        
            See also
                curl_global_init_mem(3), curl_global_cleanup(3), curl_global_sslset(3), curl_easy_init(3) libcurl(3)
        */

        ;can't find the various flag values so it's locked to the default "everything" mode for now - prolly okay
        if DllCall(this.curlDLLpath "\curl_global_init", "Int", 0x03, "CDecl")  ;returns 0 on success
            throw ValueError("Problem in 'curl_global_init'! Unable to init DLL!", -1, this.curlDLLpath)
        else
            return

    }
    _curl_global_init_mem() {

    }
    _curl_global_sslset() {

    }
    _curl_mime_addpart() {

    }
    _curl_mime_data() {

    }
    _curl_mime_data_cb() {

    }
    _curl_mime_encoder() {

    }
    _curl_mime_filedata() {

    }
    _curl_mime_filename() {

    }
    _curl_mime_free() {

    }
    _curl_mime_headers() {

    }
    _curl_mime_init() {

    }
    _curl_mime_name() {

    }
    _curl_mime_subparts() {

    }
    _curl_mime_type() {

    }
    _curl_multi_add_handle() {

    }
    _curl_multi_assign() {

    }
    _curl_multi_cleanup() {

    }
    _curl_multi_fdset() {

    }
    _curl_multi_info_read() {

    }
    _curl_multi_init() {

    }
    _curl_multi_perform() {

    }
    _curl_multi_remove_handle() {

    }
    _curl_multi_setopt() {

    }
    _curl_multi_socket_action() {

    }
    _curl_multi_strerror() {

    }
    _curl_multi_timeout() {

    }
    _curl_multi_poll() {

    }
    _curl_multi_wait() {

    }
    _curl_multi_wakeup() {

    }
    _curl_pushheader_byname() {

    }
    _curl_pushheader_bynum() {

    }
    _curl_share_cleanup() {

    }
    _curl_share_init() {

    }
    _curl_share_setopt() {

    }
    _curl_share_strerror() {

    }
    _curl_slist_append() {

    }
    _curl_slist_free_all() {

    }
    _curl_url() {

    }
    _curl_url_cleanup() {

    }
    _curl_url_dup() {

    }
    _curl_url_get() {

    }
    _curl_url_set() {

    }
    _curl_url_strerror() {

    }
    _curl_version() {
        /* https://curl.se/libcurl/c/curl_version.html
            curl_version - returns the libcurl version string
        
            Synopsis
                #include <curl/curl.h>
                char *curl_version();
        
            Description
                 - Returns a human readable string with the version number of libcurl and some of its important components (like OpenSSL version).
                 - We recommend using curl_version_info instead!
        
            Example
                 - printf("libcurl version %s\n", curl_version());
        
            Availability
             - Always
        
            Return value
                 - A pointer to a null-terminated string. The string resides in a statically allocated buffer and must not be freed by the caller.
        */

        return StrGet(DllCall(this.curlDLLpath "\curl_version", "char", 0, "ptr"), "UTF-8")
    }
    _curl_version_info() {
        /*  https://curl.se/libcurl/c/curl_version_info.html
            curl_version_info - returns run-time libcurl version info

            Synopsis
                #include <curl/curl.h>
 
                curl_version_info_data *curl_version_info( CURLversion age);

            Description
                 - Returns a pointer to a filled in static struct with information about various features in the running version of libcurl. Age should be set to the version of this functionality by the time you write your program. This way, libcurl will always return a proper struct that your program understands, while programs in the future might get a different struct. CURLVERSION_NOW will be the most recent one for the library you have installed: data = curl_version_info(CURLVERSION_NOW);
                 - Applications should use this information to judge if things are possible to do or not, instead of using compile-time checks, as dynamic/DLL libraries can be changed independent of applications.
                 - This function can alter the returned static data as long as curl_global_init has not been called. It is therefore not thread-safe before libcurl initialization occurs.

            The curl_version_info_data struct looks like this
            typedef struct {
                CURLversion age;          /* see description below
                const char *version;      /* human readable string
                unsigned int version_num; /* numeric representation
                const char *host;         /* human readable string
                int features;             /* bitmask, see below
                char *ssl_version;        /* human readable string
                long ssl_version_num;     /* not used, always zero
                const char *libz_version; /* human readable string
                const char *const *protocols; /* protocols
 
                /* when 'age' is CURLVERSION_SECOND or higher, the members below exist
                const char *ares;         /* human readable string
                int ares_num;             /* number
 
                /* when 'age' is CURLVERSION_THIRD or higher, the members below exist
                const char *libidn;       /* human readable string
 
                /* when 'age' is CURLVERSION_FOURTH or higher (>= 7.16.1), the members below exist
                int iconv_ver_num;       /* '_libiconv_version' if iconv support enabled
 
                const char *libssh_version; /* human readable string
 
                /* when 'age' is CURLVERSION_FIFTH or higher (>= 7.57.0), the members below exist
                unsigned int brotli_ver_num; /* Numeric Brotli version (MAJOR << 24) | (MINOR << 12) | PATCH
                const char *brotli_version; /* human readable string.
 
                /* when 'age' is CURLVERSION_SIXTH or higher (>= 7.66.0), the members below exist
                unsigned int nghttp2_ver_num; /* Numeric nghttp2 version (MAJOR << 16) | (MINOR << 8) | PATCH
                const char *nghttp2_version; /* human readable string.
                const char *quic_version;    /* human readable quic (+ HTTP/3) library +version or NULL
 
                /* when 'age' is CURLVERSION_SEVENTH or higher (>= 7.70.0), the members below exist
                const char *cainfo;          /* the built-in default CURLOPT_CAINFO, might be NULL
                const char *capath;          /* the built-in default CURLOPT_CAPATH, might be NULL
                
                /* when 'age' is CURLVERSION_EIGHTH or higher (>= 7.71.0), the members below exist
                unsigned int zstd_ver_num; /* Numeric Zstd version (MAJOR << 24) | (MINOR << 12) | PATCH
                const char *zstd_version; /* human readable string.
                
                /* when 'age' is CURLVERSION_NINTH or higher (>= 7.75.0), the members below exist
                const char *hyper_version; /* human readable string.
                
                /* when 'age' is CURLVERSION_TENTH or higher (>= 7.77.0), the members below exist
                const char *gsasl_version; /* human readable string.
                /* when 'age' is CURLVERSION_ELEVENTH or higher (>= 7.87.0), the members below exist
                const char *const *feature_names; /* Feature names.
            } curl_version_info_data;

             - age describes what the age of this struct is. The number depends on how new the libcurl you are using is. You are however guaranteed to get a struct that you have a matching struct for in the header, as you tell libcurl your "age" with the input argument.
             - version is just an ascii string for the libcurl version.
             - version_num is a 24 bit number created like this: <8 bits major number> | <8 bits minor number> | <8 bits patch number>. Version 7.9.8 is therefore returned as 0x070908.
             - host is an ascii string showing what host information that this libcurl was built for. As discovered by a configure script or set by the build environment.
             - features is a bit mask representing available features. It can have none, one or more bits set. The use of this field is deprecated: use feature_names instead. The feature names description below lists the associated bits.
             - feature_names is a pointer to an array of string pointers, containing the names of the features that libcurl supports. The array is terminated by a NULL entry. Currently defined names are:
                alt-svc
                    features mask bit: CURL_VERSION_ALTSVC
                    HTTP Alt-Svc parsing and the associated options (Added in 7.64.1)
                AsynchDNS
                    features mask bit: CURL_VERSION_ASYNCHDNS
                    libcurl was built with support for asynchronous name lookups, which allows more exact timeouts (even on Windows) and less blocking when using the multi interface. (added in 7.10.7)
                brotli
                    features mask bit: CURL_VERSION_BROTLI
                    supports HTTP Brotli content encoding using libbrotlidec (Added in 7.57.0)
                Debug
                    features mask bit: CURL_VERSION_DEBUG
                    libcurl was built with debug capabilities (added in 7.10.6)
                gsasl
                    features mask bit: CURL_VERSION_GSASL
                    libcurl was built with libgsasl and thus with some extra SCRAM-SHA authentication methods. (added in 7.76.0)
                GSS-API
                    features mask bit: CURL_VERSION_GSSAPI
                    libcurl was built with support for GSS-API. This makes libcurl use provided functions for Kerberos and SPNEGO authentication. It also allows libcurl to use the current user credentials without the app having to pass them on. (Added in 7.38.0)
                HSTS
                    features mask bit: CURL_VERSION_HSTS
                    libcurl was built with support for HSTS (HTTP Strict Transport Security) (Added in 7.74.0)
                HTTP2
                    features mask bit: CURL_VERSION_HTTP2
                    libcurl was built with support for HTTP2. (Added in 7.33.0)
                HTTP3
                    features mask bit: CURL_VERSION_HTTP3
                    HTTP/3 and QUIC support are built-in (Added in 7.66.0)
                HTTPS-proxy
                    features mask bit: CURL_VERSION_HTTPS_PROXY
                    libcurl was built with support for HTTPS-proxy. (Added in 7.52.0)
                IDN
                    features mask bit: CURL_VERSION_IDN
                    libcurl was built with support for IDNA, domain names with international letters. (Added in 7.12.0)
                IPv6
                    features mask bit: CURL_VERSION_IPV6
                    supports IPv6
                Kerberos
                    features mask bit: CURL_VERSION_KERBEROS5
                    supports Kerberos V5 authentication for FTP, IMAP, LDAP, POP3, SMTP and SOCKSv5 proxy. (Added in 7.40.0)
                Largefile
                    features mask bit: CURL_VERSION_LARGEFILE
                    libcurl was built with support for large files. (Added in 7.11.1)
                libz
                    features mask bit: CURL_VERSION_LIBZ
                    supports HTTP deflate using libz (Added in 7.10)
                MultiSSL
                    features mask bit: CURL_VERSION_MULTI_SSL
                    libcurl was built with multiple SSL backends. For details, see curl_global_sslset. (Added in 7.56.0)
                NTLM
                    features mask bit: CURL_VERSION_NTLM
                    supports HTTP NTLM (added in 7.10.6)
                NTLM_WB
                    features mask bit: CURL_VERSION_NTLM_WB
                    libcurl was built with support for NTLM delegation to a winbind helper. (Added in 7.22.0)
                PSL
                    features mask bit: CURL_VERSION_PSL
                    libcurl was built with support for Mozilla's Public Suffix List. This makes libcurl ignore cookies with a domain that is on the list. (Added in 7.47.0)
                SPNEGO
                    features mask bit: CURL_VERSION_SPNEGO
                    libcurl was built with support for SPNEGO authentication (Simple and Protected GSS-API Negotiation Mechanism, defined in RFC 2478.) (added in 7.10.8)
                SSL
                    features mask bit: CURL_VERSION_SSL
                    supports SSL (HTTPS/FTPS) (Added in 7.10)
                SSPI
                    features mask bit: CURL_VERSION_SSPI
                    libcurl was built with support for SSPI. This is only available on Windows and makes libcurl use Windows-provided functions for Kerberos, NTLM, SPNEGO and Digest authentication. It also allows libcurl to use the current user credentials without the app having to pass them on. (Added in 7.13.2)
                threadsafe
                    features mask bit: CURL_VERSION_THREADSAFE
                    libcurl was built with thread-safety support (Atomic or SRWLOCK) to protect curl initialization. (Added in 7.84.0) See libcurl-thread
                TLS-SRP
                    features mask bit: CURL_VERSION_TLSAUTH_SRP
                    libcurl was built with support for TLS-SRP (in one or more of the built-in TLS backends). (Added in 7.21.4)
                TrackMemory
                    features mask bit: CURL_VERSION_CURLDEBUG
                    libcurl was built with memory tracking debug capabilities. This is mainly of interest for libcurl hackers. (added in 7.19.6)
                Unicode
                    features mask bit: CURL_VERSION_UNICODE
                    libcurl was built with Unicode support on Windows. This makes non-ASCII characters work in filenames and options passed to libcurl. (Added in 7.72.0)
                UnixSockets
                    features mask bit: CURL_VERSION_UNIX_SOCKETS
                    libcurl was built with support for Unix domain sockets. (Added in 7.40.0)
                zstd
                    features mask bit: CURL_VERSION_ZSTD
                    supports HTTP zstd content encoding using zstd library (Added in 7.72.0)
                none
                    features mask bit: CURL_VERSION_CONV
                    libcurl was built with support for character conversions, as provided by the CURLOPT_CONV_* callbacks. Always 0 since 7.82.0. (Added in 7.15.4)
                none
                    features mask bit: CURL_VERSION_GSSNEGOTIATE
                    supports HTTP GSS-Negotiate (added in 7.10.6, deprecated in 7.38.0)
                none
                    features mask bit: CURL_VERSION_KERBEROS4
                    supports Kerberos V4 (when using FTP). Legacy bit. Deprecated since 7.33.0.
                    ssl_version is an ASCII string for the TLS library name + version used. If libcurl has no SSL support, this is NULL. For example "Schannel", "Secure Transport" or "OpenSSL/1.1.0g".
                    ssl_version_num is always 0.
                    libz_version is an ASCII string (there is no numerical version). If libcurl has no libz support, this is NULL.
                    protocols is a pointer to an array of char * pointers, containing the names protocols that libcurl supports (using lowercase letters). The protocol names are the same as would be used in URLs. The array is terminated by a NULL entry.

                Example
                    curl_version_info_data *ver = curl_version_info(CURLVERSION_NOW);
                    printf("libcurl version %u.%u.%u\n",
                        (ver->version_num >> 16) & 0xff,
                        (ver->version_num >> 8) & 0xff,
                        ver->version_num & 0xff);

                Availability
                    Added in 7.10

                Return value
                    A pointer to a curl_version_info_data struct.

                See also
                    curl_version
        */
        verPtr := DllCall(this.curlDLLpath "\curl_version_info", "Int", 0xA, "Ptr")
        
        ;build initial struct string 
        structStr := ""
            .   "Int    age;"
            .   "UPtr   version;"
            .   "UInt   version_num;"
            .   "UPtr   host;"
            .   "Int    features;"
            .   "UPtr   ssl_version;"
            .   "Int    ssl_version_num;"
            .   "UPtr   libz_version;"
            .   "Ptr    protocols;"
        verStruct := Struct(structStr,verPtr)
        
        verAge := verStruct["age"]
        
        ;add features to the struct until we catch up with curl age
        if (verAge >= 1){  
            structStr .= ""
                .   "UPtr   ares;"
                .   "Int    ares_num;"
        }
        if (verAge >= 2){
            structStr .= ""
                .   "UPtr   libidn;"
        }
        if (verAge >= 3){
            structStr .= ""
                .   "Int    iconv_ver_num;"
                .   "UPtr   libssh_version;"
        }
        if (verAge >= 4){
            structStr .= ""
                .   "UInt   brotli_ver_num;"
                .   "UPtr   brotli_version;"
        }
        if (verAge >= 5){
            structStr .= ""
                .   "UInt   nghttp2_ver_num;"
                .   "UPtr   nghttp2_version;"
                .   "UPtr   quic_version;"
        }
        if (verAge >= 6){
            structStr .= ""
                .   "UPtr   cainfo;"
                .   "UPtr   capath;"
        }
        if (verAge >= 7){
            structStr .= ""
                .   "UInt   zstd_ver_num;"
                .   "UPtr   zstd_version;"
        }
        if (verAge >= 8){
            structStr .= ""
                .   "UPtr   hyper_version;"
        }
        if (verAge >= 9){
            structStr .= ""
                .   "UPtr   gsasl_version;"
        }
        if (verAge >= 10){
            structStr .= ""
                .   "Ptr    feature_names;"
        }
        
        
        
        verStruct := Struct(structStr,verPtr)
        ;for k,v in verStruct
        ;    msgbox k " : " v

        retObj := Map()
        retObj["age"] := (verStruct["age"]+1)
        retObj["version"] := StrGet(verStruct["version"], "UTF-8")
        retObj["host"] := StrGet(verStruct["host"], "UTF-8")
        retObj["ssl_version"] := StrGet(verStruct["ssl_version"], "UTF-8")
        retObj["libz_version"] := StrGet(verStruct["libz_version"], "UTF-8")

        for k,v in this._walkPtrArray(verStruct["protocols"])
           prot .= v "; "
        retObj["protocols"] := Trim(prot,"; ")

        If (verStruct["age"] >= 1)
            retObj["ares"] := (verStruct["ares"]=0?0:StrGet(verStruct["ares"], "UTF-8"))
        If (verStruct["age"] >= 2)
            retObj["libidn"] := (verStruct["libidn"]=0?0:StrGet(verStruct["libidn"], "UTF-8"))
        If (verStruct["age"] >= 3){
            retObj["iconv_ver_num"] := (verStruct["iconv_ver_num"]=0?0:NumGet(verStruct["iconv_ver_num"],"Int"))
            retObj["libssh_version"] := (verStruct["libssh_version"]=0?0:StrGet(verStruct["libssh_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 4){
            ;retObj["brotli_ver_num"] := (verStruct["brotli_ver_num"]=0?0:NumGet(verStruct["brotli_ver_num"],"Int"))
            retObj["brotli_version"] := (verStruct["brotli_version"]=0?0:StrGet(verStruct["brotli_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 5){
            ;retObj["nghttp2_ver_num"] := (verStruct["nghttp2_ver_num"]=0?0:NumGet(verStruct["nghttp2_ver_num"],"UInt"))
            retObj["nghttp2_version"] := (verStruct["nghttp2_version"]=0?0:StrGet(verStruct["nghttp2_version"], "UTF-8"))
            retObj["quic_version"] := (verStruct["quic_version"]=0?0:StrGet(verStruct["quic_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 6){
            ;retObj["nghttp2_ver_num"] := (verStruct["nghttp2_ver_num"]=0?0:NumGet(verStruct["nghttp2_ver_num"],"UInt"))
            retObj["cainfo"] := (verStruct["cainfo"]=0?0:StrGet(verStruct["cainfo"], "UTF-8"))
            retObj["capath"] := (verStruct["capath"]=0?0:StrGet(verStruct["capath"], "UTF-8"))
        }
        If (verStruct["age"] >= 7){
            ;retObj["zstd_ver_num"] := (verStruct["zstd_ver_num"]=0?0:NumGet(verStruct["zstd_ver_num"],"Int"))
            retObj["zstd_version"] := (verStruct["zstd_version"]=0?0:StrGet(verStruct["zstd_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 8){
            retObj["hyper_version"] := (verStruct["hyper_version"]=0?0:StrGet(verStruct["hyper_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 9){
            retObj["gsasl_version"] := (verStruct["gsasl_version"]=0?0:StrGet(verStruct["gsasl_version"], "UTF-8"))
        }
        If (verStruct["age"] >= 10){
            for k,v in this._walkPtrArray(verStruct["feature_names"])
                feat .= v "; "
             retObj["feature_names"] := Trim(feat,"; ")
        }

        return retObj
    }
    _curl_ws_recv() {

    }
    _curl_ws_send() {

    }
    _curl_ws_meta() {

    }


    ;helper methods
    _walkPtrArray(inPtr){
        retObj := []
        loop {
            pFeature := NumGet(inPtr + ((A_Index-1) * A_PtrSize), "Ptr")
            if (pFeature = 0) {
                break
            }
            ;msgbox inPtr "`n" pFeature
            retObj.push(StrGet(pFeature,"UTF-8"))
        }
        return retObj
    }



    
    _walkStringArray2(ptr,inLen){
        offset := 0
        retObj := []
        loop inLen+5 {
            current := NumGet(ptr,"UChar")
            if (current != 0)
                retObj .= Chr(current) a_tab current "`n"
            else
                retObj .= "<<<0>>>`n"
            ptr += 1
        }
        return retObj
    }
    _walkStringArray(ptr){
        offset := 0
        loop{
            ret := StrGet(ptr, "UTF-8")
            retLen := StrLen(ret)
            if (retLen > 0){
                retStr .= ret "`n"
                ptr += retLen+1
            }
            else
                break
        }
        return retStr
    }
    _walkStringArray1(ptr){
        offset := 0
        loop{
            ret := StrGet(ptr, "UTF-8")
            retLen := StrLen(ret)
            if (retLen > 0){
                retStr .= ret "`n"
            }
            else
                break
            ptr += retLen
            endCheck := NumGet(ptr,"UShort")
            if (endCheck = 0)
                break
            else
                ptr += 1
        }
        return retStr
    }
    StringToBase64(String, Encoding := "UTF-8")
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CRYPT_STRING_NOCRLF := 0x40000000
    
        Binary := Buffer(StrPut(String, Encoding))
        StrPut(String, Binary, Encoding)
        if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &Size := 0))
            throw OSError()
    
        Base64 := Buffer(Size << 1, 0)
        if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", Binary, "UInt", Binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", Base64, "UInt*", Size))
            throw OSError()
    
        return StrGet(Base64)
    }
}