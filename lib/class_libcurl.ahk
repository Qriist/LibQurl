class class_libcurl {

    static curlDLL := ""
    static curlDLLpath := ""
    register(dllPath := ""){
        if !FileExist(dllPath)
            throw ValueError("libcurl DLL not found!", -1, dllPath)
        this.curlDLLpath := dllpath
        this.curlDLL := DllCall("LoadLibrary","Str",dllPath,"Ptr")   ;load the DLL into resident memory

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
    _curl_easy_reset() {

    }
    _curl_easy_send() {

    }
    _curl_easy_setopt() {

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

    }
    _curl_version_info() {

    }
    _curl_ws_recv() {

    }
    _curl_ws_send() {

    }
    _curl_ws_meta() {

    }
}