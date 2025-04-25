# LibQurl
This is a full [libcurl](https://curl.se/) wrap for AHKv2.

Much work has been done to abstract away the need for a full understanding of curl's rather arcane architecture, while still allowing complete access to those inner workings when required.

## Features
- This is a full direct binding of libcurl, meaning that you have access* to all functions.
- libcurl's "easy" interface is completely wrapped in a user-friendly way.
- Seamless async transfers are possible if desired.
- Transparently compressed transfers are on by default - this saves bandwidth and time.
- Numerous simultaneous curl handles are supported, as is the multi interface. All options are remembered per-handle.
- The ability to download a file directly into RAM without touching the disk - very useful when working with APIs.
- Effortless POSTing of data from almost any source, be it a String, Integer, Object, Array, Map, Buffer, or even a FileObject.
- Similarly effortless building of complex MIME forms, with the same smart source handling.
- You can manually send and receive protocol-level raw data.
- Full support for [Descolada](https://github.com/Descolada)'s fantastic AHK package manager, [Aris](https://github.com/Descolada/Aris). (This is the recommended installation method!)

<sup><sub>*Around 25 dll functions were added in an "untested" state and are clearly marked as such. Among these, there are almost certainly some instances of providing the wrong data type in the DllCall. *Caveat emptor* until checked off on the function list below. Most common functions are already properly wrapped.</sup></sub>

## Roadmap
- [X] Establish basic communication with the DLL
- [X] Wrap Easy
- [ ] Wrap Multi
- [ ] Wrap Multi_Socket
- [ ] Wrap misc functions that weren't required by any of the above
- [ ] Externally unify the Easy, Multi, and Multi_Socket calls (if possible!)

## Random to-do list, in no real order
- add handling for Opts with scaffolding during the batch SetOpts
- gather and clean the SetOpts after a handle finishes downloading
- build the debug callback
- write an "output to null" callback function for more safely reseting file writes (currently resets to memory output)
- add the other origin types to GetAllHeaders
  
<details><summary>Implemented Functions</summary>
https://curl.se/libcurl/c/allfuncs.html
  
| Wrapped?   | Name                          | Notes                        |
|:----------:|:------------------------------|:-----------------------------|
| &check;    | curl_easy_cleanup             |                              |
| &check;    | curl_easy_duphandle           |                              |
| &check;    | curl_easy_getinfo             |                              |
| &check;    | curl_easy_header              |                              |
| &check;    | curl_easy_init                |                              |
| &check;    | curl_easy_nextheader          |                              |
| &check;    | curl_easy_option_by_id        |                              |
| &check;    | curl_easy_option_by_name      |                              |
| &check;    | curl_easy_option_next         |                              |
| &check;    | curl_easy_pause               |                              |
| &check;    | curl_easy_perform             | called with .Sync()          |
| &check;    | curl_easy_recv                |                              |
| &check;    | curl_easy_reset               |                              |
| &check;    | curl_easy_send                |                              |
| &check;    | curl_easy_setopt              |                              |
| &check;    | curl_easy_strerror            |                              |
| &check;    | curl_easy_upkeep              |                              |
| &check;    | curl_free                     |                              |
| &check;    | curl_getdate                  |                              |
|            | curl_global_cleanup           |                              |
| &check;    | curl_global_init              | only default mode for now    |
|            | curl_global_init_mem          |                              |
| &check;    | curl_global_sslset            |                              |
| &check;    | curl_mime_addpart             |                              |
| &check;    | curl_mime_data                |                              |
|            | curl_mime_data_cb             |                              |
| &check;    | curl_mime_encoder             |                              |
| &check;    | curl_mime_filedata            |                              |
| &check;    | curl_mime_filename            |                              |
| &check;    | curl_mime_free                |                              |
| &check;    | curl_mime_headers             |                              |
| &check;    | curl_mime_init                |                              |
| &check;    | curl_mime_name                |                              |
| &check;    | curl_mime_subparts            |                              |
| &check;    | curl_mime_type                |                              |
| &check;    | curl_multi_add_handle         | called with .ReadySync()     |
|            | curl_multi_assign             |                              |
| &check;    | curl_multi_cleanup            |                              |
|            | curl_multi_fdset              |                              |
| &check;    | curl_multi_info_read          |                              |
| &check;    | curl_multi_init               |                              |
| &check;    | curl_multi_perform            | called with .Async()         |
| &check;    | curl_multi_remove_handle      |                              |
| &check;    | curl_multi_setopt             |                              |
|            | curl_multi_socket_action      |                              |
| &check;    | curl_multi_strerror           |                              |
|            | curl_multi_timeout            |                              |
|            | curl_multi_poll               |                              |
|            | curl_multi_wait               |                              |
|            | curl_multi_wakeup             |                              |
|            | curl_pushheader_byname        |                              |
|            | curl_pushheader_bynum         |                              |
| &check;    | curl_share_cleanup            |                              |
| &check;    | curl_share_init               |                              |
| &check;    | curl_share_setopt             |                              |
| &check;    | curl_share_strerror           |                              |
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
<details><summary>Deprecated Functions with Suggested Alternatives</summary>
  
| Wrapped?   | Name                          | Alternative                  |
|:----------:|:------------------------------|:-----------------------------|
| &#10060;   | curl_easy_escape<br>curl_easy_unescape<br>curl_escape<br>curl_unescape | use the URL API  |
| &#10060;   | curl_formadd<br>curl_formfree<br>curl_formget | use the mime API |
</summary>
</details>

