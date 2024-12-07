# LibQurl
This is a full libcurl wrap for AHKv2.

Much work has been done to abstract away the need for a full understanding of curl's rather arcane architecture, while still allowing complete access to those inner workings when required.

## Features
- This is a full direct binding of libcurl, meaning that you have access* to all functions.
- libcurl's "easy" interface is currently mostly wrapped in a user-friendly way.
- Seamless async transfers are possible if desired.
- Transparently compressed transfers are on by default - this saves bandwidth and time.
- Numerous simultaneous curl handles are supported, as is the multi interface. All options are remembered per-handle.
- The ability to download a file directly into RAM without touching the disk - very useful when working with APIs.
- Effortless POSTing of data from almost any source, be it a String, Integer, Object, Array, Map, or even a FileObject.
- Full support for [Descolada](https://github.com/Descolada)'s fantastic AHK package manager, [Aris](https://github.com/Descolada/Aris). (This is the recommended installation method!)

<sup><sub>*Around 50 dll functions were added in an "untested" state and are clearly marked as such. Among these, there are almost certainly some instances of providing the wrong data type in the DllCall. *Caveat emptor* until checked off on the function list below. Most common functions are already properly wrapped.</sup></sub>

## Roadmap
- [X] Establish basic communication with the DLL
- [ ] Get feature list from DLL and dynamically enable/disable class features
- [ ] Wrap Easy
- [ ] Wrap Multi
- [ ] Wrap Multi_Socket
- [ ] Wrap misc functions that weren't required by any of the above
- [ ] Externally unify the Easy, Multi, and Multi_Socket calls (if possible!)

## Random to-do list, in no real order
- enable preloading sslset
- auto-updating the cert bundle
- add handling for Opts with scaffolding during the batch SetOpts
- gather and clean the SetOpts after a handle finishes downloading
- investigate POST mode differences (probably when I wrap the mime API)
- build the read/progress/debug callbacks
- write an "output to null" callback function for more safely reseting file writes (currently resets to memory output)
- build the multi opt map
- build the share opt map
- create callback that reads POSTed file incrementally
- add the other origin types to GetAllHeaders
  
<details><summary>Implemented Functions</summary>
https://curl.se/libcurl/c/allfuncs.html
  
| Wrapped?   | Name                          | Notes                        |
|:----------:|:------------------------------|:-----------------------------|
| &check;    | curl_easy_cleanup             |                              |
| &check;    | curl_easy_duphandle           |                              |
| &check;    | curl_easy_escape              |                              |
| &check;    | curl_easy_getinfo             |                              |
| &check;    | curl_easy_header              |                              |
| &check;    | curl_easy_init                |                              |
| &check;    | curl_easy_nextheader          |                              |
| &check;    | curl_easy_option_by_id        |                              |
| &check;    | curl_easy_option_by_name      |                              |
| &check;    | curl_easy_option_next         |                              |
|            | curl_easy_pause               |                              |
| &check;    | curl_easy_perform             |                              |
|            | curl_easy_recv                |                              |
| &check;    | curl_easy_reset               |                              |
|            | curl_easy_send                |                              |
| &check;    | curl_easy_setopt              |                              |
| &check;    | curl_easy_strerror            |                              |
|            | curl_easy_unescape            |                              |
|            | curl_easy_upkeep              |                              |
| &#10060;   | curl_formadd                  | deprecated                   |
| &#10060;   | curl_formfree                 | deprecated                   |
| &#10060;   | curl_formget                  | deprecated                   |
| &check;    | curl_free                     |                              |
|            | curl_getdate                  |                              |
|            | curl_global_cleanup           |                              |
| &check;    | curl_global_init              | only default mode for now    |
|            | curl_global_init_mem          |                              |
|            | curl_global_sslset            |                              |
|            | curl_mime_addpart             |                              |
|            | curl_mime_data                |                              |
|            | curl_mime_data_cb             |                              |
|            | curl_mime_encoder             |                              |
|            | curl_mime_filedata            |                              |
|            | curl_mime_filename            |                              |
|            | curl_mime_free                |                              |
|            | curl_mime_headers             |                              |
|            | curl_mime_init                |                              |
|            | curl_mime_name                |                              |
|            | curl_mime_subparts            |                              |
|            | curl_mime_type                |                              |
| &check;    | curl_multi_add_handle         |                              |
|            | curl_multi_assign             |                              |
|            | curl_multi_cleanup            |                              |
|            | curl_multi_fdset              |                              |
| &check;    | curl_multi_info_read          |                              |
| &check;    | curl_multi_init               |                              |
| &check;    | curl_multi_perform            |                              |
| &check;    | curl_multi_remove_handle      |                              |
|            | curl_multi_setopt             |                              |
|            | curl_multi_socket_action      |                              |
|            | curl_multi_strerror           |                              |
|            | curl_multi_timeout            |                              |
|            | curl_multi_poll               |                              |
|            | curl_multi_wait               |                              |
|            | curl_multi_wakeup             |                              |
|            | curl_pushheader_byname        |                              |
|            | curl_pushheader_bynum         |                              |
|            | curl_share_cleanup            |                              |
|            | curl_share_init               |                              |
|            | curl_share_setopt             |                              |
|            | curl_share_strerror           |                              |
| &check;    | curl_slist_append             |                              |
| &check;    | curl_slist_free_all           |                              |
| &check;    | curl_url                      |                              |
| &check;    | curl_url_cleanup              |                              |
| &check;    | curl_url_dup                  |                              |
| &check;    | curl_url_get                  |                              |
| &check;    | curl_url_set                  |                              |
| &check;    | curl_url_strerror             |                              |
| &check;    | curl_version                  |                              |
| &check;    | curl_version_info             |                              |
|            | curl_ws_recv                  |                              |
|            | curl_ws_send                  |                              |
|            | curl_ws_meta                  |                              |
</details>
