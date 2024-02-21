class class_libcurl {
    hCURL := Map()
    static curlDLLhandle := ""
    static curlDLLpath := ""
    Opt := Map()
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
    _curl_easy_escape(handle,url) {
        ;doesn't like unicode, should I use the native windows function for this?
        ;char *curl_easy_escape(CURL *curl, const char *string, int length);
        esc := DllCall(this.curlDLLpath "\curl_easy_escape"
            ,"Ptr",handle
            ,"AStr",url
            ,"Int",0
            ,"Ptr")
        return StrGet(esc,"UTF-8")

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
    _curl_easy_option_by_id(id) {
        ;returns from the pre-built array
        If this.optMap.Has(id)
            return this.optMap[id]
        return 0
    }
    _curl_easy_option_by_name(name) {
        ;returns from the pre-built array
        If this.optMap.Has(name)
            return this.optMap[name]
        return 0

        ; retCode := DllCall(this.curlDLLpath "\curl_easy_option_by_name"
        ;     ,"AStr",name
        ;     ,"Ptr")
        ; return retCode
    }
    _curl_easy_option_next() {

    }
    _curl_easy_pause() {

    }
    _curl_easy_perform(handle) {
        retCode := DllCall(this.curlDLLpath "\curl_easy_perform"
            ,"Ptr",handle)
        return retCode
    }
    _curl_easy_recv() {

    }
    _curl_easy_reset(handle) {
        DllCall(this.curlDLLpath "\curl_easy_reset"
            ,"Ptr",handle)
    }
    _curl_easy_send() {

    }
    _curl_easy_setopt(handle,option,parameter) {
        retCode := DllCall(this.curlDLLpath "\curl_easy_setopt"
            ,"Ptr",handle
            ,"Int",option
            ,"AStr",parameter)
        return retCode
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
    _buildOptMap() {    ;creates a reference matrix of all known SETCURLOPTs
        optObj(id,name,type){
            return {id:id+10000,name:name,type:type}
        }
        this.Opt["CURLOPT_WRITEDATA"] := this.Opt["WRITEDATA"] := this.Opt[1] := this.Opt[10001] := optObj(1,"WRITEDATA","CBPOINT")
        this.Opt["CURLOPT_URL"] := this.Opt["URL"] := this.Opt[2] := this.Opt[10002] := optObj(2,"URL","STRINGPOINT")
        this.Opt["CURLOPT_PORT"] := this.Opt["PORT"] := this.Opt[3] := this.Opt[10003] := optObj(3,"PORT","LONG")
        this.Opt["CURLOPT_PROXY"] := this.Opt["PROXY"] := this.Opt[4] := this.Opt[10004] := optObj(4,"PROXY","STRINGPOINT")
        this.Opt["CURLOPT_USERPWD"] := this.Opt["USERPWD"] := this.Opt[5] := this.Opt[10005] := optObj(5,"USERPWD","STRINGPOINT")
        this.Opt["CURLOPT_PROXYUSERPWD"] := this.Opt["PROXYUSERPWD"] := this.Opt[6] := this.Opt[10006] := optObj(6,"PROXYUSERPWD","STRINGPOINT")
        this.Opt["CURLOPT_RANGE"] := this.Opt["RANGE"] := this.Opt[7] := this.Opt[10007] := optObj(7,"RANGE","STRINGPOINT")
        this.Opt["CURLOPT_READDATA"] := this.Opt["READDATA"] := this.Opt[9] := this.Opt[10009] := optObj(9,"READDATA","CBPOINT")
        this.Opt["CURLOPT_ERRORBUFFER"] := this.Opt["ERRORBUFFER"] := this.Opt[10] := this.Opt[10010] := optObj(10,"ERRORBUFFER","OBJECTPOINT")
        this.Opt["CURLOPT_WRITEFUNCTION"] := this.Opt["WRITEFUNCTION"] := this.Opt[11] := this.Opt[10011] := optObj(11,"WRITEFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_READFUNCTION"] := this.Opt["READFUNCTION"] := this.Opt[12] := this.Opt[10012] := optObj(12,"READFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_TIMEOUT"] := this.Opt["TIMEOUT"] := this.Opt[13] := this.Opt[10013] := optObj(13,"TIMEOUT","LONG")
        this.Opt["CURLOPT_INFILESIZE"] := this.Opt["INFILESIZE"] := this.Opt[14] := this.Opt[10014] := optObj(14,"INFILESIZE","LONG")
        this.Opt["CURLOPT_POSTFIELDS"] := this.Opt["POSTFIELDS"] := this.Opt[15] := this.Opt[10015] := optObj(15,"POSTFIELDS","OBJECTPOINT")
        this.Opt["CURLOPT_REFERER"] := this.Opt["REFERER"] := this.Opt[16] := this.Opt[10016] := optObj(16,"REFERER","STRINGPOINT")
        this.Opt["CURLOPT_FTPPORT"] := this.Opt["FTPPORT"] := this.Opt[17] := this.Opt[10017] := optObj(17,"FTPPORT","STRINGPOINT")
        this.Opt["CURLOPT_USERAGENT"] := this.Opt["USERAGENT"] := this.Opt[18] := this.Opt[10018] := optObj(18,"USERAGENT","STRINGPOINT")
        this.Opt["CURLOPT_LOW_SPEED_LIMIT"] := this.Opt["LOW_SPEED_LIMIT"] := this.Opt[19] := this.Opt[10019] := optObj(19,"LOW_SPEED_LIMIT","LONG")
        this.Opt["CURLOPT_LOW_SPEED_TIME"] := this.Opt["LOW_SPEED_TIME"] := this.Opt[20] := this.Opt[10020] := optObj(20,"LOW_SPEED_TIME","LONG")
        this.Opt["CURLOPT_RESUME_FROM"] := this.Opt["RESUME_FROM"] := this.Opt[21] := this.Opt[10021] := optObj(21,"RESUME_FROM","LONG")
        this.Opt["CURLOPT_COOKIE"] := this.Opt["COOKIE"] := this.Opt[22] := this.Opt[10022] := optObj(22,"COOKIE","STRINGPOINT")
        this.Opt["CURLOPT_HTTPHEADER"] := this.Opt["HTTPHEADER"] := this.Opt[23] := this.Opt[10023] := optObj(23,"HTTPHEADER","SLISTPOINT")
        this.Opt["CURLOPT_SSLCERT"] := this.Opt["SSLCERT"] := this.Opt[25] := this.Opt[10025] := optObj(25,"SSLCERT","STRINGPOINT")
        this.Opt["CURLOPT_KEYPASSWD"] := this.Opt["KEYPASSWD"] := this.Opt[26] := this.Opt[10026] := optObj(26,"KEYPASSWD","STRINGPOINT")
        this.Opt["CURLOPT_CRLF"] := this.Opt["CRLF"] := this.Opt[27] := this.Opt[10027] := optObj(27,"CRLF","LONG")
        this.Opt["CURLOPT_QUOTE"] := this.Opt["QUOTE"] := this.Opt[28] := this.Opt[10028] := optObj(28,"QUOTE","SLISTPOINT")
        this.Opt["CURLOPT_HEADERDATA"] := this.Opt["HEADERDATA"] := this.Opt[29] := this.Opt[10029] := optObj(29,"HEADERDATA","CBPOINT")
        this.Opt["CURLOPT_COOKIEFILE"] := this.Opt["COOKIEFILE"] := this.Opt[31] := this.Opt[10031] := optObj(31,"COOKIEFILE","STRINGPOINT")
        this.Opt["CURLOPT_SSLVERSION"] := this.Opt["SSLVERSION"] := this.Opt[32] := this.Opt[10032] := optObj(32,"SSLVERSION","VALUES")
        this.Opt["CURLOPT_TIMECONDITION"] := this.Opt["TIMECONDITION"] := this.Opt[33] := this.Opt[10033] := optObj(33,"TIMECONDITION","VALUES")
        this.Opt["CURLOPT_TIMEVALUE"] := this.Opt["TIMEVALUE"] := this.Opt[34] := this.Opt[10034] := optObj(34,"TIMEVALUE","LONG")
        this.Opt["CURLOPT_CUSTOMREQUEST"] := this.Opt["CUSTOMREQUEST"] := this.Opt[36] := this.Opt[10036] := optObj(36,"CUSTOMREQUEST","STRINGPOINT")
        this.Opt["CURLOPT_STDERR"] := this.Opt["STDERR"] := this.Opt[37] := this.Opt[10037] := optObj(37,"STDERR","OBJECTPOINT")
        this.Opt["CURLOPT_POSTQUOTE"] := this.Opt["POSTQUOTE"] := this.Opt[39] := this.Opt[10039] := optObj(39,"POSTQUOTE","SLISTPOINT")
        this.Opt["CURLOPT_OBSOLETE40"] := this.Opt["OBSOLETE40"] := this.Opt[40] := this.Opt[10040] := optObj(40,"OBSOLETE40","OBJECTPOINT")
        this.Opt["CURLOPT_VERBOSE"] := this.Opt["VERBOSE"] := this.Opt[41] := this.Opt[10041] := optObj(41,"VERBOSE","LONG")
        this.Opt["CURLOPT_HEADER"] := this.Opt["HEADER"] := this.Opt[42] := this.Opt[10042] := optObj(42,"HEADER","LONG")
        this.Opt["CURLOPT_NOPROGRESS"] := this.Opt["NOPROGRESS"] := this.Opt[43] := this.Opt[10043] := optObj(43,"NOPROGRESS","LONG")
        this.Opt["CURLOPT_NOBODY"] := this.Opt["NOBODY"] := this.Opt[44] := this.Opt[10044] := optObj(44,"NOBODY","LONG")
        this.Opt["CURLOPT_FAILONERROR"] := this.Opt["FAILONERROR"] := this.Opt[45] := this.Opt[10045] := optObj(45,"FAILONERROR","LONG")
        this.Opt["CURLOPT_UPLOAD"] := this.Opt["UPLOAD"] := this.Opt[46] := this.Opt[10046] := optObj(46,"UPLOAD","LONG")
        this.Opt["CURLOPT_POST"] := this.Opt["POST"] := this.Opt[47] := this.Opt[10047] := optObj(47,"POST","LONG")
        this.Opt["CURLOPT_DIRLISTONLY"] := this.Opt["DIRLISTONLY"] := this.Opt[48] := this.Opt[10048] := optObj(48,"DIRLISTONLY","LONG")
        this.Opt["CURLOPT_APPEND"] := this.Opt["APPEND"] := this.Opt[50] := this.Opt[10050] := optObj(50,"APPEND","LONG")
        this.Opt["CURLOPT_NETRC"] := this.Opt["NETRC"] := this.Opt[51] := this.Opt[10051] := optObj(51,"NETRC","VALUES")
        this.Opt["CURLOPT_FOLLOWLOCATION"] := this.Opt["FOLLOWLOCATION"] := this.Opt[52] := this.Opt[10052] := optObj(52,"FOLLOWLOCATION","LONG")
        this.Opt["CURLOPT_TRANSFERTEXT"] := this.Opt["TRANSFERTEXT"] := this.Opt[53] := this.Opt[10053] := optObj(53,"TRANSFERTEXT","LONG")
        this.Opt["CURLOPT_XFERINFODATA"] := this.Opt["XFERINFODATA"] := this.Opt[57] := this.Opt[10057] := optObj(57,"XFERINFODATA","CBPOINT")
        this.Opt["CURLOPT_AUTOREFERER"] := this.Opt["AUTOREFERER"] := this.Opt[58] := this.Opt[10058] := optObj(58,"AUTOREFERER","LONG")
        this.Opt["CURLOPT_PROXYPORT"] := this.Opt["PROXYPORT"] := this.Opt[59] := this.Opt[10059] := optObj(59,"PROXYPORT","LONG")
        this.Opt["CURLOPT_POSTFIELDSIZE"] := this.Opt["POSTFIELDSIZE"] := this.Opt[60] := this.Opt[10060] := optObj(60,"POSTFIELDSIZE","LONG")
        this.Opt["CURLOPT_HTTPPROXYTUNNEL"] := this.Opt["HTTPPROXYTUNNEL"] := this.Opt[61] := this.Opt[10061] := optObj(61,"HTTPPROXYTUNNEL","LONG")
        this.Opt["CURLOPT_INTERFACE"] := this.Opt["INTERFACE"] := this.Opt[62] := this.Opt[10062] := optObj(62,"INTERFACE","STRINGPOINT")
        this.Opt["CURLOPT_KRBLEVEL"] := this.Opt["KRBLEVEL"] := this.Opt[63] := this.Opt[10063] := optObj(63,"KRBLEVEL","STRINGPOINT")
        this.Opt["CURLOPT_SSL_VERIFYPEER"] := this.Opt["SSL_VERIFYPEER"] := this.Opt[64] := this.Opt[10064] := optObj(64,"SSL_VERIFYPEER","LONG")
        this.Opt["CURLOPT_CAINFO"] := this.Opt["CAINFO"] := this.Opt[65] := this.Opt[10065] := optObj(65,"CAINFO","STRINGPOINT")
        this.Opt["CURLOPT_MAXREDIRS"] := this.Opt["MAXREDIRS"] := this.Opt[68] := this.Opt[10068] := optObj(68,"MAXREDIRS","LONG")
        this.Opt["CURLOPT_FILETIME"] := this.Opt["FILETIME"] := this.Opt[69] := this.Opt[10069] := optObj(69,"FILETIME","LONG")
        this.Opt["CURLOPT_TELNETOPTIONS"] := this.Opt["TELNETOPTIONS"] := this.Opt[70] := this.Opt[10070] := optObj(70,"TELNETOPTIONS","SLISTPOINT")
        this.Opt["CURLOPT_MAXCONNECTS"] := this.Opt["MAXCONNECTS"] := this.Opt[71] := this.Opt[10071] := optObj(71,"MAXCONNECTS","LONG")
        this.Opt["CURLOPT_OBSOLETE72"] := this.Opt["OBSOLETE72"] := this.Opt[72] := this.Opt[10072] := optObj(72,"OBSOLETE72","LONG")
        this.Opt["CURLOPT_FRESH_CONNECT"] := this.Opt["FRESH_CONNECT"] := this.Opt[74] := this.Opt[10074] := optObj(74,"FRESH_CONNECT","LONG")
        this.Opt["CURLOPT_FORBID_REUSE"] := this.Opt["FORBID_REUSE"] := this.Opt[75] := this.Opt[10075] := optObj(75,"FORBID_REUSE","LONG")
        this.Opt["CURLOPT_CONNECTTIMEOUT"] := this.Opt["CONNECTTIMEOUT"] := this.Opt[78] := this.Opt[10078] := optObj(78,"CONNECTTIMEOUT","LONG")
        this.Opt["CURLOPT_HEADERFUNCTION"] := this.Opt["HEADERFUNCTION"] := this.Opt[79] := this.Opt[10079] := optObj(79,"HEADERFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_HTTPGET"] := this.Opt["HTTPGET"] := this.Opt[80] := this.Opt[10080] := optObj(80,"HTTPGET","LONG")
        this.Opt["CURLOPT_SSL_VERIFYHOST"] := this.Opt["SSL_VERIFYHOST"] := this.Opt[81] := this.Opt[10081] := optObj(81,"SSL_VERIFYHOST","LONG")
        this.Opt["CURLOPT_COOKIEJAR"] := this.Opt["COOKIEJAR"] := this.Opt[82] := this.Opt[10082] := optObj(82,"COOKIEJAR","STRINGPOINT")
        this.Opt["CURLOPT_SSL_CIPHER_LIST"] := this.Opt["SSL_CIPHER_LIST"] := this.Opt[83] := this.Opt[10083] := optObj(83,"SSL_CIPHER_LIST","STRINGPOINT")
        this.Opt["CURLOPT_HTTP_VERSION"] := this.Opt["HTTP_VERSION"] := this.Opt[84] := this.Opt[10084] := optObj(84,"HTTP_VERSION","VALUES")
        this.Opt["CURLOPT_FTP_USE_EPSV"] := this.Opt["FTP_USE_EPSV"] := this.Opt[85] := this.Opt[10085] := optObj(85,"FTP_USE_EPSV","LONG")
        this.Opt["CURLOPT_SSLCERTTYPE"] := this.Opt["SSLCERTTYPE"] := this.Opt[86] := this.Opt[10086] := optObj(86,"SSLCERTTYPE","STRINGPOINT")
        this.Opt["CURLOPT_SSLKEY"] := this.Opt["SSLKEY"] := this.Opt[87] := this.Opt[10087] := optObj(87,"SSLKEY","STRINGPOINT")
        this.Opt["CURLOPT_SSLKEYTYPE"] := this.Opt["SSLKEYTYPE"] := this.Opt[88] := this.Opt[10088] := optObj(88,"SSLKEYTYPE","STRINGPOINT")
        this.Opt["CURLOPT_SSLENGINE"] := this.Opt["SSLENGINE"] := this.Opt[89] := this.Opt[10089] := optObj(89,"SSLENGINE","STRINGPOINT")
        this.Opt["CURLOPT_SSLENGINE_DEFAULT"] := this.Opt["SSLENGINE_DEFAULT"] := this.Opt[90] := this.Opt[10090] := optObj(90,"SSLENGINE_DEFAULT","LONG")
        this.Opt["CURLOPT_DNS_CACHE_TIMEOUT"] := this.Opt["DNS_CACHE_TIMEOUT"] := this.Opt[92] := this.Opt[10092] := optObj(92,"DNS_CACHE_TIMEOUT","LONG")
        this.Opt["CURLOPT_PREQUOTE"] := this.Opt["PREQUOTE"] := this.Opt[93] := this.Opt[10093] := optObj(93,"PREQUOTE","SLISTPOINT")
        this.Opt["CURLOPT_DEBUGFUNCTION"] := this.Opt["DEBUGFUNCTION"] := this.Opt[94] := this.Opt[10094] := optObj(94,"DEBUGFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_DEBUGDATA"] := this.Opt["DEBUGDATA"] := this.Opt[95] := this.Opt[10095] := optObj(95,"DEBUGDATA","CBPOINT")
        this.Opt["CURLOPT_COOKIESESSION"] := this.Opt["COOKIESESSION"] := this.Opt[96] := this.Opt[10096] := optObj(96,"COOKIESESSION","LONG")
        this.Opt["CURLOPT_CAPATH"] := this.Opt["CAPATH"] := this.Opt[97] := this.Opt[10097] := optObj(97,"CAPATH","STRINGPOINT")
        this.Opt["CURLOPT_BUFFERSIZE"] := this.Opt["BUFFERSIZE"] := this.Opt[98] := this.Opt[10098] := optObj(98,"BUFFERSIZE","LONG")
        this.Opt["CURLOPT_NOSIGNAL"] := this.Opt["NOSIGNAL"] := this.Opt[99] := this.Opt[10099] := optObj(99,"NOSIGNAL","LONG")
        this.Opt["CURLOPT_SHARE"] := this.Opt["SHARE"] := this.Opt[100] := this.Opt[10100] := optObj(100,"SHARE","OBJECTPOINT")
        this.Opt["CURLOPT_PROXYTYPE"] := this.Opt["PROXYTYPE"] := this.Opt[101] := this.Opt[10101] := optObj(101,"PROXYTYPE","VALUES")
        this.Opt["CURLOPT_ACCEPT_ENCODING"] := this.Opt["ACCEPT_ENCODING"] := this.Opt[102] := this.Opt[10102] := optObj(102,"ACCEPT_ENCODING","STRINGPOINT")
        this.Opt["CURLOPT_PRIVATE"] := this.Opt["PRIVATE"] := this.Opt[103] := this.Opt[10103] := optObj(103,"PRIVATE","OBJECTPOINT")
        this.Opt["CURLOPT_HTTP200ALIASES"] := this.Opt["HTTP200ALIASES"] := this.Opt[104] := this.Opt[10104] := optObj(104,"HTTP200ALIASES","SLISTPOINT")
        this.Opt["CURLOPT_UNRESTRICTED_AUTH"] := this.Opt["UNRESTRICTED_AUTH"] := this.Opt[105] := this.Opt[10105] := optObj(105,"UNRESTRICTED_AUTH","LONG")
        this.Opt["CURLOPT_FTP_USE_EPRT"] := this.Opt["FTP_USE_EPRT"] := this.Opt[106] := this.Opt[10106] := optObj(106,"FTP_USE_EPRT","LONG")
        this.Opt["CURLOPT_HTTPAUTH"] := this.Opt["HTTPAUTH"] := this.Opt[107] := this.Opt[10107] := optObj(107,"HTTPAUTH","VALUES")
        this.Opt["CURLOPT_SSL_CTX_FUNCTION"] := this.Opt["SSL_CTX_FUNCTION"] := this.Opt[108] := this.Opt[10108] := optObj(108,"SSL_CTX_FUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_SSL_CTX_DATA"] := this.Opt["SSL_CTX_DATA"] := this.Opt[109] := this.Opt[10109] := optObj(109,"SSL_CTX_DATA","CBPOINT")
        this.Opt["CURLOPT_FTP_CREATE_MISSING_DIRS"] := this.Opt["FTP_CREATE_MISSING_DIRS"] := this.Opt[110] := this.Opt[10110] := optObj(110,"FTP_CREATE_MISSING_DIRS","LONG")
        this.Opt["CURLOPT_PROXYAUTH"] := this.Opt["PROXYAUTH"] := this.Opt[111] := this.Opt[10111] := optObj(111,"PROXYAUTH","VALUES")
        this.Opt["CURLOPT_SERVER_RESPONSE_TIMEOUT"] := this.Opt["SERVER_RESPONSE_TIMEOUT"] := this.Opt[112] := this.Opt[10112] := optObj(112,"SERVER_RESPONSE_TIMEOUT","LONG")
        this.Opt["CURLOPT_IPRESOLVE"] := this.Opt["IPRESOLVE"] := this.Opt[113] := this.Opt[10113] := optObj(113,"IPRESOLVE","VALUES")
        this.Opt["CURLOPT_MAXFILESIZE"] := this.Opt["MAXFILESIZE"] := this.Opt[114] := this.Opt[10114] := optObj(114,"MAXFILESIZE","LONG")
        this.Opt["CURLOPT_INFILESIZE_LARGE"] := this.Opt["INFILESIZE_LARGE"] := this.Opt[115] := this.Opt[10115] := optObj(115,"INFILESIZE_LARGE","OFF_T")
        this.Opt["CURLOPT_RESUME_FROM_LARGE"] := this.Opt["RESUME_FROM_LARGE"] := this.Opt[116] := this.Opt[10116] := optObj(116,"RESUME_FROM_LARGE","OFF_T")
        this.Opt["CURLOPT_MAXFILESIZE_LARGE"] := this.Opt["MAXFILESIZE_LARGE"] := this.Opt[117] := this.Opt[10117] := optObj(117,"MAXFILESIZE_LARGE","OFF_T")
        this.Opt["CURLOPT_NETRC_FILE"] := this.Opt["NETRC_FILE"] := this.Opt[118] := this.Opt[10118] := optObj(118,"NETRC_FILE","STRINGPOINT")
        this.Opt["CURLOPT_USE_SSL"] := this.Opt["USE_SSL"] := this.Opt[119] := this.Opt[10119] := optObj(119,"USE_SSL","VALUES")
        this.Opt["CURLOPT_POSTFIELDSIZE_LARGE"] := this.Opt["POSTFIELDSIZE_LARGE"] := this.Opt[120] := this.Opt[10120] := optObj(120,"POSTFIELDSIZE_LARGE","OFF_T")
        this.Opt["CURLOPT_TCP_NODELAY"] := this.Opt["TCP_NODELAY"] := this.Opt[121] := this.Opt[10121] := optObj(121,"TCP_NODELAY","LONG")
        this.Opt["CURLOPT_FTPSSLAUTH"] := this.Opt["FTPSSLAUTH"] := this.Opt[129] := this.Opt[10129] := optObj(129,"FTPSSLAUTH","VALUES")
        this.Opt["CURLOPT_FTP_ACCOUNT"] := this.Opt["FTP_ACCOUNT"] := this.Opt[134] := this.Opt[10134] := optObj(134,"FTP_ACCOUNT","STRINGPOINT")
        this.Opt["CURLOPT_COOKIELIST"] := this.Opt["COOKIELIST"] := this.Opt[135] := this.Opt[10135] := optObj(135,"COOKIELIST","STRINGPOINT")
        this.Opt["CURLOPT_IGNORE_CONTENT_LENGTH"] := this.Opt["IGNORE_CONTENT_LENGTH"] := this.Opt[136] := this.Opt[10136] := optObj(136,"IGNORE_CONTENT_LENGTH","LONG")
        this.Opt["CURLOPT_FTP_SKIP_PASV_IP"] := this.Opt["FTP_SKIP_PASV_IP"] := this.Opt[137] := this.Opt[10137] := optObj(137,"FTP_SKIP_PASV_IP","LONG")
        this.Opt["CURLOPT_FTP_FILEMETHOD"] := this.Opt["FTP_FILEMETHOD"] := this.Opt[138] := this.Opt[10138] := optObj(138,"FTP_FILEMETHOD","VALUES")
        this.Opt["CURLOPT_LOCALPORT"] := this.Opt["LOCALPORT"] := this.Opt[139] := this.Opt[10139] := optObj(139,"LOCALPORT","LONG")
        this.Opt["CURLOPT_LOCALPORTRANGE"] := this.Opt["LOCALPORTRANGE"] := this.Opt[140] := this.Opt[10140] := optObj(140,"LOCALPORTRANGE","LONG")
        this.Opt["CURLOPT_CONNECT_ONLY"] := this.Opt["CONNECT_ONLY"] := this.Opt[141] := this.Opt[10141] := optObj(141,"CONNECT_ONLY","LONG")
        this.Opt["CURLOPT_MAX_SEND_SPEED_LARGE"] := this.Opt["MAX_SEND_SPEED_LARGE"] := this.Opt[145] := this.Opt[10145] := optObj(145,"MAX_SEND_SPEED_LARGE","OFF_T")
        this.Opt["CURLOPT_MAX_RECV_SPEED_LARGE"] := this.Opt["MAX_RECV_SPEED_LARGE"] := this.Opt[146] := this.Opt[10146] := optObj(146,"MAX_RECV_SPEED_LARGE","OFF_T")
        this.Opt["CURLOPT_FTP_ALTERNATIVE_TO_USER"] := this.Opt["FTP_ALTERNATIVE_TO_USER"] := this.Opt[147] := this.Opt[10147] := optObj(147,"FTP_ALTERNATIVE_TO_USER","STRINGPOINT")
        this.Opt["CURLOPT_SOCKOPTFUNCTION"] := this.Opt["SOCKOPTFUNCTION"] := this.Opt[148] := this.Opt[10148] := optObj(148,"SOCKOPTFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_SOCKOPTDATA"] := this.Opt["SOCKOPTDATA"] := this.Opt[149] := this.Opt[10149] := optObj(149,"SOCKOPTDATA","CBPOINT")
        this.Opt["CURLOPT_SSL_SESSIONID_CACHE"] := this.Opt["SSL_SESSIONID_CACHE"] := this.Opt[150] := this.Opt[10150] := optObj(150,"SSL_SESSIONID_CACHE","LONG")
        this.Opt["CURLOPT_SSH_AUTH_TYPES"] := this.Opt["SSH_AUTH_TYPES"] := this.Opt[151] := this.Opt[10151] := optObj(151,"SSH_AUTH_TYPES","VALUES")
        this.Opt["CURLOPT_SSH_PUBLIC_KEYFILE"] := this.Opt["SSH_PUBLIC_KEYFILE"] := this.Opt[152] := this.Opt[10152] := optObj(152,"SSH_PUBLIC_KEYFILE","STRINGPOINT")
        this.Opt["CURLOPT_SSH_PRIVATE_KEYFILE"] := this.Opt["SSH_PRIVATE_KEYFILE"] := this.Opt[153] := this.Opt[10153] := optObj(153,"SSH_PRIVATE_KEYFILE","STRINGPOINT")
        this.Opt["CURLOPT_FTP_SSL_CCC"] := this.Opt["FTP_SSL_CCC"] := this.Opt[154] := this.Opt[10154] := optObj(154,"FTP_SSL_CCC","LONG")
        this.Opt["CURLOPT_TIMEOUT_MS"] := this.Opt["TIMEOUT_MS"] := this.Opt[155] := this.Opt[10155] := optObj(155,"TIMEOUT_MS","LONG")
        this.Opt["CURLOPT_CONNECTTIMEOUT_MS"] := this.Opt["CONNECTTIMEOUT_MS"] := this.Opt[156] := this.Opt[10156] := optObj(156,"CONNECTTIMEOUT_MS","LONG")
        this.Opt["CURLOPT_HTTP_TRANSFER_DECODING"] := this.Opt["HTTP_TRANSFER_DECODING"] := this.Opt[157] := this.Opt[10157] := optObj(157,"HTTP_TRANSFER_DECODING","LONG")
        this.Opt["CURLOPT_HTTP_CONTENT_DECODING"] := this.Opt["HTTP_CONTENT_DECODING"] := this.Opt[158] := this.Opt[10158] := optObj(158,"HTTP_CONTENT_DECODING","LONG")
        this.Opt["CURLOPT_NEW_FILE_PERMS"] := this.Opt["NEW_FILE_PERMS"] := this.Opt[159] := this.Opt[10159] := optObj(159,"NEW_FILE_PERMS","LONG")
        this.Opt["CURLOPT_NEW_DIRECTORY_PERMS"] := this.Opt["NEW_DIRECTORY_PERMS"] := this.Opt[160] := this.Opt[10160] := optObj(160,"NEW_DIRECTORY_PERMS","LONG")
        this.Opt["CURLOPT_POSTREDIR"] := this.Opt["POSTREDIR"] := this.Opt[161] := this.Opt[10161] := optObj(161,"POSTREDIR","VALUES")
        this.Opt["CURLOPT_SSH_HOST_PUBLIC_KEY_MD5"] := this.Opt["SSH_HOST_PUBLIC_KEY_MD5"] := this.Opt[162] := this.Opt[10162] := optObj(162,"SSH_HOST_PUBLIC_KEY_MD5","STRINGPOINT")
        this.Opt["CURLOPT_OPENSOCKETFUNCTION"] := this.Opt["OPENSOCKETFUNCTION"] := this.Opt[163] := this.Opt[10163] := optObj(163,"OPENSOCKETFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_OPENSOCKETDATA"] := this.Opt["OPENSOCKETDATA"] := this.Opt[164] := this.Opt[10164] := optObj(164,"OPENSOCKETDATA","CBPOINT")
        this.Opt["CURLOPT_COPYPOSTFIELDS"] := this.Opt["COPYPOSTFIELDS"] := this.Opt[165] := this.Opt[10165] := optObj(165,"COPYPOSTFIELDS","OBJECTPOINT")
        this.Opt["CURLOPT_PROXY_TRANSFER_MODE"] := this.Opt["PROXY_TRANSFER_MODE"] := this.Opt[166] := this.Opt[10166] := optObj(166,"PROXY_TRANSFER_MODE","LONG")
        this.Opt["CURLOPT_SEEKFUNCTION"] := this.Opt["SEEKFUNCTION"] := this.Opt[167] := this.Opt[10167] := optObj(167,"SEEKFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_SEEKDATA"] := this.Opt["SEEKDATA"] := this.Opt[168] := this.Opt[10168] := optObj(168,"SEEKDATA","CBPOINT")
        this.Opt["CURLOPT_CRLFILE"] := this.Opt["CRLFILE"] := this.Opt[169] := this.Opt[10169] := optObj(169,"CRLFILE","STRINGPOINT")
        this.Opt["CURLOPT_ISSUERCERT"] := this.Opt["ISSUERCERT"] := this.Opt[170] := this.Opt[10170] := optObj(170,"ISSUERCERT","STRINGPOINT")
        this.Opt["CURLOPT_ADDRESS_SCOPE"] := this.Opt["ADDRESS_SCOPE"] := this.Opt[171] := this.Opt[10171] := optObj(171,"ADDRESS_SCOPE","LONG")
        this.Opt["CURLOPT_CERTINFO"] := this.Opt["CERTINFO"] := this.Opt[172] := this.Opt[10172] := optObj(172,"CERTINFO","LONG")
        this.Opt["CURLOPT_USERNAME"] := this.Opt["USERNAME"] := this.Opt[173] := this.Opt[10173] := optObj(173,"USERNAME","STRINGPOINT")
        this.Opt["CURLOPT_PASSWORD"] := this.Opt["PASSWORD"] := this.Opt[174] := this.Opt[10174] := optObj(174,"PASSWORD","STRINGPOINT")
        this.Opt["CURLOPT_PROXYUSERNAME"] := this.Opt["PROXYUSERNAME"] := this.Opt[175] := this.Opt[10175] := optObj(175,"PROXYUSERNAME","STRINGPOINT")
        this.Opt["CURLOPT_PROXYPASSWORD"] := this.Opt["PROXYPASSWORD"] := this.Opt[176] := this.Opt[10176] := optObj(176,"PROXYPASSWORD","STRINGPOINT")
        this.Opt["CURLOPT_NOPROXY"] := this.Opt["NOPROXY"] := this.Opt[177] := this.Opt[10177] := optObj(177,"NOPROXY","STRINGPOINT")
        this.Opt["CURLOPT_TFTP_BLKSIZE"] := this.Opt["TFTP_BLKSIZE"] := this.Opt[178] := this.Opt[10178] := optObj(178,"TFTP_BLKSIZE","LONG")
        this.Opt["CURLOPT_SOCKS5_GSSAPI_NEC"] := this.Opt["SOCKS5_GSSAPI_NEC"] := this.Opt[180] := this.Opt[10180] := optObj(180,"SOCKS5_GSSAPI_NEC","LONG")
        this.Opt["CURLOPT_SSH_KNOWNHOSTS"] := this.Opt["SSH_KNOWNHOSTS"] := this.Opt[183] := this.Opt[10183] := optObj(183,"SSH_KNOWNHOSTS","STRINGPOINT")
        this.Opt["CURLOPT_SSH_KEYFUNCTION"] := this.Opt["SSH_KEYFUNCTION"] := this.Opt[184] := this.Opt[10184] := optObj(184,"SSH_KEYFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_SSH_KEYDATA"] := this.Opt["SSH_KEYDATA"] := this.Opt[185] := this.Opt[10185] := optObj(185,"SSH_KEYDATA","CBPOINT")
        this.Opt["CURLOPT_MAIL_FROM"] := this.Opt["MAIL_FROM"] := this.Opt[186] := this.Opt[10186] := optObj(186,"MAIL_FROM","STRINGPOINT")
        this.Opt["CURLOPT_MAIL_RCPT"] := this.Opt["MAIL_RCPT"] := this.Opt[187] := this.Opt[10187] := optObj(187,"MAIL_RCPT","SLISTPOINT")
        this.Opt["CURLOPT_FTP_USE_PRET"] := this.Opt["FTP_USE_PRET"] := this.Opt[188] := this.Opt[10188] := optObj(188,"FTP_USE_PRET","LONG")
        this.Opt["CURLOPT_RTSP_REQUEST"] := this.Opt["RTSP_REQUEST"] := this.Opt[189] := this.Opt[10189] := optObj(189,"RTSP_REQUEST","VALUES")
        this.Opt["CURLOPT_RTSP_SESSION_ID"] := this.Opt["RTSP_SESSION_ID"] := this.Opt[190] := this.Opt[10190] := optObj(190,"RTSP_SESSION_ID","STRINGPOINT")
        this.Opt["CURLOPT_RTSP_STREAM_URI"] := this.Opt["RTSP_STREAM_URI"] := this.Opt[191] := this.Opt[10191] := optObj(191,"RTSP_STREAM_URI","STRINGPOINT")
        this.Opt["CURLOPT_RTSP_TRANSPORT"] := this.Opt["RTSP_TRANSPORT"] := this.Opt[192] := this.Opt[10192] := optObj(192,"RTSP_TRANSPORT","STRINGPOINT")
        this.Opt["CURLOPT_RTSP_CLIENT_CSEQ"] := this.Opt["RTSP_CLIENT_CSEQ"] := this.Opt[193] := this.Opt[10193] := optObj(193,"RTSP_CLIENT_CSEQ","LONG")
        this.Opt["CURLOPT_RTSP_SERVER_CSEQ"] := this.Opt["RTSP_SERVER_CSEQ"] := this.Opt[194] := this.Opt[10194] := optObj(194,"RTSP_SERVER_CSEQ","LONG")
        this.Opt["CURLOPT_INTERLEAVEDATA"] := this.Opt["INTERLEAVEDATA"] := this.Opt[195] := this.Opt[10195] := optObj(195,"INTERLEAVEDATA","CBPOINT")
        this.Opt["CURLOPT_INTERLEAVEFUNCTION"] := this.Opt["INTERLEAVEFUNCTION"] := this.Opt[196] := this.Opt[10196] := optObj(196,"INTERLEAVEFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_WILDCARDMATCH"] := this.Opt["WILDCARDMATCH"] := this.Opt[197] := this.Opt[10197] := optObj(197,"WILDCARDMATCH","LONG")
        this.Opt["CURLOPT_CHUNK_BGN_FUNCTION"] := this.Opt["CHUNK_BGN_FUNCTION"] := this.Opt[198] := this.Opt[10198] := optObj(198,"CHUNK_BGN_FUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_CHUNK_END_FUNCTION"] := this.Opt["CHUNK_END_FUNCTION"] := this.Opt[199] := this.Opt[10199] := optObj(199,"CHUNK_END_FUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_FNMATCH_FUNCTION"] := this.Opt["FNMATCH_FUNCTION"] := this.Opt[200] := this.Opt[10200] := optObj(200,"FNMATCH_FUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_CHUNK_DATA"] := this.Opt["CHUNK_DATA"] := this.Opt[201] := this.Opt[10201] := optObj(201,"CHUNK_DATA","CBPOINT")
        this.Opt["CURLOPT_FNMATCH_DATA"] := this.Opt["FNMATCH_DATA"] := this.Opt[202] := this.Opt[10202] := optObj(202,"FNMATCH_DATA","CBPOINT")
        this.Opt["CURLOPT_RESOLVE"] := this.Opt["RESOLVE"] := this.Opt[203] := this.Opt[10203] := optObj(203,"RESOLVE","SLISTPOINT")
        this.Opt["CURLOPT_TLSAUTH_USERNAME"] := this.Opt["TLSAUTH_USERNAME"] := this.Opt[204] := this.Opt[10204] := optObj(204,"TLSAUTH_USERNAME","STRINGPOINT")
        this.Opt["CURLOPT_TLSAUTH_PASSWORD"] := this.Opt["TLSAUTH_PASSWORD"] := this.Opt[205] := this.Opt[10205] := optObj(205,"TLSAUTH_PASSWORD","STRINGPOINT")
        this.Opt["CURLOPT_TLSAUTH_TYPE"] := this.Opt["TLSAUTH_TYPE"] := this.Opt[206] := this.Opt[10206] := optObj(206,"TLSAUTH_TYPE","STRINGPOINT")
        this.Opt["CURLOPT_TRANSFER_ENCODING"] := this.Opt["TRANSFER_ENCODING"] := this.Opt[207] := this.Opt[10207] := optObj(207,"TRANSFER_ENCODING","LONG")
        this.Opt["CURLOPT_CLOSESOCKETFUNCTION"] := this.Opt["CLOSESOCKETFUNCTION"] := this.Opt[208] := this.Opt[10208] := optObj(208,"CLOSESOCKETFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_CLOSESOCKETDATA"] := this.Opt["CLOSESOCKETDATA"] := this.Opt[209] := this.Opt[10209] := optObj(209,"CLOSESOCKETDATA","CBPOINT")
        this.Opt["CURLOPT_GSSAPI_DELEGATION"] := this.Opt["GSSAPI_DELEGATION"] := this.Opt[210] := this.Opt[10210] := optObj(210,"GSSAPI_DELEGATION","VALUES")
        this.Opt["CURLOPT_DNS_SERVERS"] := this.Opt["DNS_SERVERS"] := this.Opt[211] := this.Opt[10211] := optObj(211,"DNS_SERVERS","STRINGPOINT")
        this.Opt["CURLOPT_ACCEPTTIMEOUT_MS"] := this.Opt["ACCEPTTIMEOUT_MS"] := this.Opt[212] := this.Opt[10212] := optObj(212,"ACCEPTTIMEOUT_MS","LONG")
        this.Opt["CURLOPT_TCP_KEEPALIVE"] := this.Opt["TCP_KEEPALIVE"] := this.Opt[213] := this.Opt[10213] := optObj(213,"TCP_KEEPALIVE","LONG")
        this.Opt["CURLOPT_TCP_KEEPIDLE"] := this.Opt["TCP_KEEPIDLE"] := this.Opt[214] := this.Opt[10214] := optObj(214,"TCP_KEEPIDLE","LONG")
        this.Opt["CURLOPT_TCP_KEEPINTVL"] := this.Opt["TCP_KEEPINTVL"] := this.Opt[215] := this.Opt[10215] := optObj(215,"TCP_KEEPINTVL","LONG")
        this.Opt["CURLOPT_SSL_OPTIONS"] := this.Opt["SSL_OPTIONS"] := this.Opt[216] := this.Opt[10216] := optObj(216,"SSL_OPTIONS","VALUES")
        this.Opt["CURLOPT_MAIL_AUTH"] := this.Opt["MAIL_AUTH"] := this.Opt[217] := this.Opt[10217] := optObj(217,"MAIL_AUTH","STRINGPOINT")
        this.Opt["CURLOPT_SASL_IR"] := this.Opt["SASL_IR"] := this.Opt[218] := this.Opt[10218] := optObj(218,"SASL_IR","LONG")
        this.Opt["CURLOPT_XFERINFOFUNCTION"] := this.Opt["XFERINFOFUNCTION"] := this.Opt[219] := this.Opt[10219] := optObj(219,"XFERINFOFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_XOAUTH2_BEARER"] := this.Opt["XOAUTH2_BEARER"] := this.Opt[220] := this.Opt[10220] := optObj(220,"XOAUTH2_BEARER","STRINGPOINT")
        this.Opt["CURLOPT_DNS_INTERFACE"] := this.Opt["DNS_INTERFACE"] := this.Opt[221] := this.Opt[10221] := optObj(221,"DNS_INTERFACE","STRINGPOINT")
        this.Opt["CURLOPT_DNS_LOCAL_IP4"] := this.Opt["DNS_LOCAL_IP4"] := this.Opt[222] := this.Opt[10222] := optObj(222,"DNS_LOCAL_IP4","STRINGPOINT")
        this.Opt["CURLOPT_DNS_LOCAL_IP6"] := this.Opt["DNS_LOCAL_IP6"] := this.Opt[223] := this.Opt[10223] := optObj(223,"DNS_LOCAL_IP6","STRINGPOINT")
        this.Opt["CURLOPT_LOGIN_OPTIONS"] := this.Opt["LOGIN_OPTIONS"] := this.Opt[224] := this.Opt[10224] := optObj(224,"LOGIN_OPTIONS","STRINGPOINT")
        this.Opt["CURLOPT_SSL_ENABLE_ALPN"] := this.Opt["SSL_ENABLE_ALPN"] := this.Opt[226] := this.Opt[10226] := optObj(226,"SSL_ENABLE_ALPN","LONG")
        this.Opt["CURLOPT_EXPECT_100_TIMEOUT_MS"] := this.Opt["EXPECT_100_TIMEOUT_MS"] := this.Opt[227] := this.Opt[10227] := optObj(227,"EXPECT_100_TIMEOUT_MS","LONG")
        this.Opt["CURLOPT_PROXYHEADER"] := this.Opt["PROXYHEADER"] := this.Opt[228] := this.Opt[10228] := optObj(228,"PROXYHEADER","SLISTPOINT")
        this.Opt["CURLOPT_HEADEROPT"] := this.Opt["HEADEROPT"] := this.Opt[229] := this.Opt[10229] := optObj(229,"HEADEROPT","VALUES")
        this.Opt["CURLOPT_PINNEDPUBLICKEY"] := this.Opt["PINNEDPUBLICKEY"] := this.Opt[230] := this.Opt[10230] := optObj(230,"PINNEDPUBLICKEY","STRINGPOINT")
        this.Opt["CURLOPT_UNIX_SOCKET_PATH"] := this.Opt["UNIX_SOCKET_PATH"] := this.Opt[231] := this.Opt[10231] := optObj(231,"UNIX_SOCKET_PATH","STRINGPOINT")
        this.Opt["CURLOPT_SSL_VERIFYSTATUS"] := this.Opt["SSL_VERIFYSTATUS"] := this.Opt[232] := this.Opt[10232] := optObj(232,"SSL_VERIFYSTATUS","LONG")
        this.Opt["CURLOPT_SSL_FALSESTART"] := this.Opt["SSL_FALSESTART"] := this.Opt[233] := this.Opt[10233] := optObj(233,"SSL_FALSESTART","LONG")
        this.Opt["CURLOPT_PATH_AS_IS"] := this.Opt["PATH_AS_IS"] := this.Opt[234] := this.Opt[10234] := optObj(234,"PATH_AS_IS","LONG")
        this.Opt["CURLOPT_PROXY_SERVICE_NAME"] := this.Opt["PROXY_SERVICE_NAME"] := this.Opt[235] := this.Opt[10235] := optObj(235,"PROXY_SERVICE_NAME","STRINGPOINT")
        this.Opt["CURLOPT_SERVICE_NAME"] := this.Opt["SERVICE_NAME"] := this.Opt[236] := this.Opt[10236] := optObj(236,"SERVICE_NAME","STRINGPOINT")
        this.Opt["CURLOPT_PIPEWAIT"] := this.Opt["PIPEWAIT"] := this.Opt[237] := this.Opt[10237] := optObj(237,"PIPEWAIT","LONG")
        this.Opt["CURLOPT_DEFAULT_PROTOCOL"] := this.Opt["DEFAULT_PROTOCOL"] := this.Opt[238] := this.Opt[10238] := optObj(238,"DEFAULT_PROTOCOL","STRINGPOINT")
        this.Opt["CURLOPT_STREAM_WEIGHT"] := this.Opt["STREAM_WEIGHT"] := this.Opt[239] := this.Opt[10239] := optObj(239,"STREAM_WEIGHT","LONG")
        this.Opt["CURLOPT_STREAM_DEPENDS"] := this.Opt["STREAM_DEPENDS"] := this.Opt[240] := this.Opt[10240] := optObj(240,"STREAM_DEPENDS","OBJECTPOINT")
        this.Opt["CURLOPT_STREAM_DEPENDS_E"] := this.Opt["STREAM_DEPENDS_E"] := this.Opt[241] := this.Opt[10241] := optObj(241,"STREAM_DEPENDS_E","OBJECTPOINT")
        this.Opt["CURLOPT_TFTP_NO_OPTIONS"] := this.Opt["TFTP_NO_OPTIONS"] := this.Opt[242] := this.Opt[10242] := optObj(242,"TFTP_NO_OPTIONS","LONG")
        this.Opt["CURLOPT_CONNECT_TO"] := this.Opt["CONNECT_TO"] := this.Opt[243] := this.Opt[10243] := optObj(243,"CONNECT_TO","SLISTPOINT")
        this.Opt["CURLOPT_TCP_FASTOPEN"] := this.Opt["TCP_FASTOPEN"] := this.Opt[244] := this.Opt[10244] := optObj(244,"TCP_FASTOPEN","LONG")
        this.Opt["CURLOPT_KEEP_SENDING_ON_ERROR"] := this.Opt["KEEP_SENDING_ON_ERROR"] := this.Opt[245] := this.Opt[10245] := optObj(245,"KEEP_SENDING_ON_ERROR","LONG")
        this.Opt["CURLOPT_PROXY_CAINFO"] := this.Opt["PROXY_CAINFO"] := this.Opt[246] := this.Opt[10246] := optObj(246,"PROXY_CAINFO","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_CAPATH"] := this.Opt["PROXY_CAPATH"] := this.Opt[247] := this.Opt[10247] := optObj(247,"PROXY_CAPATH","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSL_VERIFYPEER"] := this.Opt["PROXY_SSL_VERIFYPEER"] := this.Opt[248] := this.Opt[10248] := optObj(248,"PROXY_SSL_VERIFYPEER","LONG")
        this.Opt["CURLOPT_PROXY_SSL_VERIFYHOST"] := this.Opt["PROXY_SSL_VERIFYHOST"] := this.Opt[249] := this.Opt[10249] := optObj(249,"PROXY_SSL_VERIFYHOST","LONG")
        this.Opt["CURLOPT_PROXY_SSLVERSION"] := this.Opt["PROXY_SSLVERSION"] := this.Opt[250] := this.Opt[10250] := optObj(250,"PROXY_SSLVERSION","VALUES")
        this.Opt["CURLOPT_PROXY_TLSAUTH_USERNAME"] := this.Opt["PROXY_TLSAUTH_USERNAME"] := this.Opt[251] := this.Opt[10251] := optObj(251,"PROXY_TLSAUTH_USERNAME","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_TLSAUTH_PASSWORD"] := this.Opt["PROXY_TLSAUTH_PASSWORD"] := this.Opt[252] := this.Opt[10252] := optObj(252,"PROXY_TLSAUTH_PASSWORD","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_TLSAUTH_TYPE"] := this.Opt["PROXY_TLSAUTH_TYPE"] := this.Opt[253] := this.Opt[10253] := optObj(253,"PROXY_TLSAUTH_TYPE","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSLCERT"] := this.Opt["PROXY_SSLCERT"] := this.Opt[254] := this.Opt[10254] := optObj(254,"PROXY_SSLCERT","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSLCERTTYPE"] := this.Opt["PROXY_SSLCERTTYPE"] := this.Opt[255] := this.Opt[10255] := optObj(255,"PROXY_SSLCERTTYPE","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSLKEY"] := this.Opt["PROXY_SSLKEY"] := this.Opt[256] := this.Opt[10256] := optObj(256,"PROXY_SSLKEY","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSLKEYTYPE"] := this.Opt["PROXY_SSLKEYTYPE"] := this.Opt[257] := this.Opt[10257] := optObj(257,"PROXY_SSLKEYTYPE","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_KEYPASSWD"] := this.Opt["PROXY_KEYPASSWD"] := this.Opt[258] := this.Opt[10258] := optObj(258,"PROXY_KEYPASSWD","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSL_CIPHER_LIST"] := this.Opt["PROXY_SSL_CIPHER_LIST"] := this.Opt[259] := this.Opt[10259] := optObj(259,"PROXY_SSL_CIPHER_LIST","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_CRLFILE"] := this.Opt["PROXY_CRLFILE"] := this.Opt[260] := this.Opt[10260] := optObj(260,"PROXY_CRLFILE","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_SSL_OPTIONS"] := this.Opt["PROXY_SSL_OPTIONS"] := this.Opt[261] := this.Opt[10261] := optObj(261,"PROXY_SSL_OPTIONS","LONG")
        this.Opt["CURLOPT_PRE_PROXY"] := this.Opt["PRE_PROXY"] := this.Opt[262] := this.Opt[10262] := optObj(262,"PRE_PROXY","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_PINNEDPUBLICKEY"] := this.Opt["PROXY_PINNEDPUBLICKEY"] := this.Opt[263] := this.Opt[10263] := optObj(263,"PROXY_PINNEDPUBLICKEY","STRINGPOINT")
        this.Opt["CURLOPT_ABSTRACT_UNIX_SOCKET"] := this.Opt["ABSTRACT_UNIX_SOCKET"] := this.Opt[264] := this.Opt[10264] := optObj(264,"ABSTRACT_UNIX_SOCKET","STRINGPOINT")
        this.Opt["CURLOPT_SUPPRESS_CONNECT_HEADERS"] := this.Opt["SUPPRESS_CONNECT_HEADERS"] := this.Opt[265] := this.Opt[10265] := optObj(265,"SUPPRESS_CONNECT_HEADERS","LONG")
        this.Opt["CURLOPT_REQUEST_TARGET"] := this.Opt["REQUEST_TARGET"] := this.Opt[266] := this.Opt[10266] := optObj(266,"REQUEST_TARGET","STRINGPOINT")
        this.Opt["CURLOPT_SOCKS5_AUTH"] := this.Opt["SOCKS5_AUTH"] := this.Opt[267] := this.Opt[10267] := optObj(267,"SOCKS5_AUTH","LONG")
        this.Opt["CURLOPT_SSH_COMPRESSION"] := this.Opt["SSH_COMPRESSION"] := this.Opt[268] := this.Opt[10268] := optObj(268,"SSH_COMPRESSION","LONG")
        this.Opt["CURLOPT_MIMEPOST"] := this.Opt["MIMEPOST"] := this.Opt[269] := this.Opt[10269] := optObj(269,"MIMEPOST","OBJECTPOINT")
        this.Opt["CURLOPT_TIMEVALUE_LARGE"] := this.Opt["TIMEVALUE_LARGE"] := this.Opt[270] := this.Opt[10270] := optObj(270,"TIMEVALUE_LARGE","OFF_T")
        this.Opt["CURLOPT_HAPPY_EYEBALLS_TIMEOUT_MS"] := this.Opt["HAPPY_EYEBALLS_TIMEOUT_MS"] := this.Opt[271] := this.Opt[10271] := optObj(271,"HAPPY_EYEBALLS_TIMEOUT_MS","LONG")
        this.Opt["CURLOPT_RESOLVER_START_FUNCTION"] := this.Opt["RESOLVER_START_FUNCTION"] := this.Opt[272] := this.Opt[10272] := optObj(272,"RESOLVER_START_FUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_RESOLVER_START_DATA"] := this.Opt["RESOLVER_START_DATA"] := this.Opt[273] := this.Opt[10273] := optObj(273,"RESOLVER_START_DATA","CBPOINT")
        this.Opt["CURLOPT_HAPROXYPROTOCOL"] := this.Opt["HAPROXYPROTOCOL"] := this.Opt[274] := this.Opt[10274] := optObj(274,"HAPROXYPROTOCOL","LONG")
        this.Opt["CURLOPT_DNS_SHUFFLE_ADDRESSES"] := this.Opt["DNS_SHUFFLE_ADDRESSES"] := this.Opt[275] := this.Opt[10275] := optObj(275,"DNS_SHUFFLE_ADDRESSES","LONG")
        this.Opt["CURLOPT_TLS13_CIPHERS"] := this.Opt["TLS13_CIPHERS"] := this.Opt[276] := this.Opt[10276] := optObj(276,"TLS13_CIPHERS","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_TLS13_CIPHERS"] := this.Opt["PROXY_TLS13_CIPHERS"] := this.Opt[277] := this.Opt[10277] := optObj(277,"PROXY_TLS13_CIPHERS","STRINGPOINT")
        this.Opt["CURLOPT_DISALLOW_USERNAME_IN_URL"] := this.Opt["DISALLOW_USERNAME_IN_URL"] := this.Opt[278] := this.Opt[10278] := optObj(278,"DISALLOW_USERNAME_IN_URL","LONG")
        this.Opt["CURLOPT_DOH_URL"] := this.Opt["DOH_URL"] := this.Opt[279] := this.Opt[10279] := optObj(279,"DOH_URL","STRINGPOINT")
        this.Opt["CURLOPT_UPLOAD_BUFFERSIZE"] := this.Opt["UPLOAD_BUFFERSIZE"] := this.Opt[280] := this.Opt[10280] := optObj(280,"UPLOAD_BUFFERSIZE","LONG")
        this.Opt["CURLOPT_UPKEEP_INTERVAL_MS"] := this.Opt["UPKEEP_INTERVAL_MS"] := this.Opt[281] := this.Opt[10281] := optObj(281,"UPKEEP_INTERVAL_MS","LONG")
        this.Opt["CURLOPT_CURLU"] := this.Opt["CURLU"] := this.Opt[282] := this.Opt[10282] := optObj(282,"CURLU","OBJECTPOINT")
        this.Opt["CURLOPT_TRAILERFUNCTION"] := this.Opt["TRAILERFUNCTION"] := this.Opt[283] := this.Opt[10283] := optObj(283,"TRAILERFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_TRAILERDATA"] := this.Opt["TRAILERDATA"] := this.Opt[284] := this.Opt[10284] := optObj(284,"TRAILERDATA","CBPOINT")
        this.Opt["CURLOPT_HTTP09_ALLOWED"] := this.Opt["HTTP09_ALLOWED"] := this.Opt[285] := this.Opt[10285] := optObj(285,"HTTP09_ALLOWED","LONG")
        this.Opt["CURLOPT_ALTSVC_CTRL"] := this.Opt["ALTSVC_CTRL"] := this.Opt[286] := this.Opt[10286] := optObj(286,"ALTSVC_CTRL","LONG")
        this.Opt["CURLOPT_ALTSVC"] := this.Opt["ALTSVC"] := this.Opt[287] := this.Opt[10287] := optObj(287,"ALTSVC","STRINGPOINT")
        this.Opt["CURLOPT_MAXAGE_CONN"] := this.Opt["MAXAGE_CONN"] := this.Opt[288] := this.Opt[10288] := optObj(288,"MAXAGE_CONN","LONG")
        this.Opt["CURLOPT_SASL_AUTHZID"] := this.Opt["SASL_AUTHZID"] := this.Opt[289] := this.Opt[10289] := optObj(289,"SASL_AUTHZID","STRINGPOINT")
        this.Opt["CURLOPT_MAIL_RCPT_ALLOWFAILS"] := this.Opt["MAIL_RCPT_ALLOWFAILS"] := this.Opt[290] := this.Opt[10290] := optObj(290,"MAIL_RCPT_ALLOWFAILS","LONG")
        this.Opt["CURLOPT_SSLCERT_BLOB"] := this.Opt["SSLCERT_BLOB"] := this.Opt[291] := this.Opt[10291] := optObj(291,"SSLCERT_BLOB","BLOB")
        this.Opt["CURLOPT_SSLKEY_BLOB"] := this.Opt["SSLKEY_BLOB"] := this.Opt[292] := this.Opt[10292] := optObj(292,"SSLKEY_BLOB","BLOB")
        this.Opt["CURLOPT_PROXY_SSLCERT_BLOB"] := this.Opt["PROXY_SSLCERT_BLOB"] := this.Opt[293] := this.Opt[10293] := optObj(293,"PROXY_SSLCERT_BLOB","BLOB")
        this.Opt["CURLOPT_PROXY_SSLKEY_BLOB"] := this.Opt["PROXY_SSLKEY_BLOB"] := this.Opt[294] := this.Opt[10294] := optObj(294,"PROXY_SSLKEY_BLOB","BLOB")
        this.Opt["CURLOPT_ISSUERCERT_BLOB"] := this.Opt["ISSUERCERT_BLOB"] := this.Opt[295] := this.Opt[10295] := optObj(295,"ISSUERCERT_BLOB","BLOB")
        this.Opt["CURLOPT_PROXY_ISSUERCERT"] := this.Opt["PROXY_ISSUERCERT"] := this.Opt[296] := this.Opt[10296] := optObj(296,"PROXY_ISSUERCERT","STRINGPOINT")
        this.Opt["CURLOPT_PROXY_ISSUERCERT_BLOB"] := this.Opt["PROXY_ISSUERCERT_BLOB"] := this.Opt[297] := this.Opt[10297] := optObj(297,"PROXY_ISSUERCERT_BLOB","BLOB")
        this.Opt["CURLOPT_SSL_EC_CURVES"] := this.Opt["SSL_EC_CURVES"] := this.Opt[298] := this.Opt[10298] := optObj(298,"SSL_EC_CURVES","STRINGPOINT")
        this.Opt["CURLOPT_HSTS_CTRL"] := this.Opt["HSTS_CTRL"] := this.Opt[299] := this.Opt[10299] := optObj(299,"HSTS_CTRL","LONG")
        this.Opt["CURLOPT_HSTS"] := this.Opt["HSTS"] := this.Opt[300] := this.Opt[10300] := optObj(300,"HSTS","STRINGPOINT")
        this.Opt["CURLOPT_HSTSREADFUNCTION"] := this.Opt["HSTSREADFUNCTION"] := this.Opt[301] := this.Opt[10301] := optObj(301,"HSTSREADFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_HSTSREADDATA"] := this.Opt["HSTSREADDATA"] := this.Opt[302] := this.Opt[10302] := optObj(302,"HSTSREADDATA","CBPOINT")
        this.Opt["CURLOPT_HSTSWRITEFUNCTION"] := this.Opt["HSTSWRITEFUNCTION"] := this.Opt[303] := this.Opt[10303] := optObj(303,"HSTSWRITEFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_HSTSWRITEDATA"] := this.Opt["HSTSWRITEDATA"] := this.Opt[304] := this.Opt[10304] := optObj(304,"HSTSWRITEDATA","CBPOINT")
        this.Opt["CURLOPT_AWS_SIGV4"] := this.Opt["AWS_SIGV4"] := this.Opt[305] := this.Opt[10305] := optObj(305,"AWS_SIGV4","STRINGPOINT")
        this.Opt["CURLOPT_DOH_SSL_VERIFYPEER"] := this.Opt["DOH_SSL_VERIFYPEER"] := this.Opt[306] := this.Opt[10306] := optObj(306,"DOH_SSL_VERIFYPEER","LONG")
        this.Opt["CURLOPT_DOH_SSL_VERIFYHOST"] := this.Opt["DOH_SSL_VERIFYHOST"] := this.Opt[307] := this.Opt[10307] := optObj(307,"DOH_SSL_VERIFYHOST","LONG")
        this.Opt["CURLOPT_DOH_SSL_VERIFYSTATUS"] := this.Opt["DOH_SSL_VERIFYSTATUS"] := this.Opt[308] := this.Opt[10308] := optObj(308,"DOH_SSL_VERIFYSTATUS","LONG")
        this.Opt["CURLOPT_CAINFO_BLOB"] := this.Opt["CAINFO_BLOB"] := this.Opt[309] := this.Opt[10309] := optObj(309,"CAINFO_BLOB","BLOB")
        this.Opt["CURLOPT_PROXY_CAINFO_BLOB"] := this.Opt["PROXY_CAINFO_BLOB"] := this.Opt[310] := this.Opt[10310] := optObj(310,"PROXY_CAINFO_BLOB","BLOB")
        this.Opt["CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256"] := this.Opt["SSH_HOST_PUBLIC_KEY_SHA256"] := this.Opt[311] := this.Opt[10311] := optObj(311,"SSH_HOST_PUBLIC_KEY_SHA256","STRINGPOINT")
        this.Opt["CURLOPT_PREREQFUNCTION"] := this.Opt["PREREQFUNCTION"] := this.Opt[312] := this.Opt[10312] := optObj(312,"PREREQFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_PREREQDATA"] := this.Opt["PREREQDATA"] := this.Opt[313] := this.Opt[10313] := optObj(313,"PREREQDATA","CBPOINT")
        this.Opt["CURLOPT_MAXLIFETIME_CONN"] := this.Opt["MAXLIFETIME_CONN"] := this.Opt[314] := this.Opt[10314] := optObj(314,"MAXLIFETIME_CONN","LONG")
        this.Opt["CURLOPT_MIME_OPTIONS"] := this.Opt["MIME_OPTIONS"] := this.Opt[315] := this.Opt[10315] := optObj(315,"MIME_OPTIONS","LONG")
        this.Opt["CURLOPT_SSH_HOSTKEYFUNCTION"] := this.Opt["SSH_HOSTKEYFUNCTION"] := this.Opt[316] := this.Opt[10316] := optObj(316,"SSH_HOSTKEYFUNCTION","FUNCTIONPOINT")
        this.Opt["CURLOPT_SSH_HOSTKEYDATA"] := this.Opt["SSH_HOSTKEYDATA"] := this.Opt[317] := this.Opt[10317] := optObj(317,"SSH_HOSTKEYDATA","CBPOINT")
        this.Opt["CURLOPT_PROTOCOLS_STR"] := this.Opt["PROTOCOLS_STR"] := this.Opt[318] := this.Opt[10318] := optObj(318,"PROTOCOLS_STR","STRINGPOINT")
        this.Opt["CURLOPT_REDIR_PROTOCOLS_STR"] := this.Opt["REDIR_PROTOCOLS_STR"] := this.Opt[319] := this.Opt[10319] := optObj(319,"REDIR_PROTOCOLS_STR","STRINGPOINT")
        this.Opt["CURLOPT_WS_OPTIONS"] := this.Opt["WS_OPTIONS"] := this.Opt[320] := this.Opt[10320] := optObj(320,"WS_OPTIONS","LONG")
        this.Opt["CURLOPT_CA_CACHE_TIMEOUT"] := this.Opt["CA_CACHE_TIMEOUT"] := this.Opt[321] := this.Opt[10321] := optObj(321,"CA_CACHE_TIMEOUT","LONG")
        this.Opt["CURLOPT_QUICK_EXIT"] := this.Opt["QUICK_EXIT"] := this.Opt[322] := this.Opt[10322] := optObj(322,"QUICK_EXIT","LONG")
        this.Opt["CURLOPT_HAPROXY_CLIENT_IP"] := this.Opt["HAPROXY_CLIENT_IP"] := this.Opt[323] := this.Opt[10323] := optObj(323,"HAPROXY_CLIENT_IP","STRINGPOINT")
        this.Opt["CURLOPT_SERVER_RESPONSE_TIMEOUT_MS"] := this.Opt["SERVER_RESPONSE_TIMEOUT_MS"] := this.Opt[324] := this.Opt[10324] := optObj(324,"SERVER_RESPONSE_TIMEOUT_MS","LONG")
    }
}