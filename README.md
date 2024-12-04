# LibQurl
Full libcurl wrap for AHKv2.

## Roadmap
- [X] Establish basic communication with the DLL
- [ ] Get feature list from DLL and dynamically enable/disable class features
- [ ] Wrap Easy
- [ ] Wrap Multi
- [ ] Wrap Multi_Socket
- [ ] Wrap misc functions that weren't required by any of the above
- [ ] Externally unify the Easy, Multi, and Multi_Socket calls (if possible!)

<details><summary>Implemented Functions</summary>
https://curl.se/libcurl/c/allfuncs.html
  
| Wrapped?   | Name                          | Notes                        |
|:----------:|:------------------------------|:-----------------------------|
| &check;    | curl_easy_cleanup             |                              |
| &check;    | curl_easy_duphandle           |                              |
| &check;    | curl_easy_escape              |                              |
|            | curl_easy_getinfo             |                              |
|            | curl_easy_header              |                              |
| &check;    | curl_easy_init                |                              |
|            | curl_easy_nextheader          |                              |
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
