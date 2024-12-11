#Requires AutoHotkey v2.0
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk

/*
    SSL *has* to be selected before anything else gets set in curl.
    In order of priority, the provider is chosen like this:
        1) the user's input string
        2) from a priority list, with WolfSSL at the top
        3) whatever curl decides

    You can safely pass would-be provider strings that your specific
    build is unaware of. Options 2 and 3 will be sequentially tried, then
    
    You can't change the SSL provider while LibQurl is active, but the
    curl.availableSSLproviders property holds a Map of all *presently* known
    SSL providers. Pass one of those names on future runs.

    Additionally curl.selectedSSLprovider holds the library/version of the 
    currently loaded provider.
*/

;partial list based on what LibQurl is distributed with
listOfSSLs := ["fakeProvider"   ;will default to WolfSSL if chosen
,   "OpenSSL"
,   "Schannel"
,   "GnuTLS"
,   "mbedTLS"]

randomSSL := Random(1,listOfSSLs.Length)
randomSSL := listOfSSLs[randomSSL]


SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl()
curl.register(A_ScriptDir "\..\bin\libcurl.dll",randomSSL)

out := "The SSL providers known to this build of libcurl are:`n`n"
out .= "( [id] => name )`n`n"
out .= curl.PrintObj(curl.availableSSLproviders) "`n`n`n"
out .= "Randomly selected SLL provider: " randomSSL "`n`n"
out .= "Currently selected SSL := " curl.selectedSSLprovider

FileOpen(A_ScriptDir "\14.results.txt","w").Write(out)