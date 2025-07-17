#Requires AutoHotkey v2.0
#include "*i <Aris\SKAN\RunCMD>" ; SKAN/RunCMD@9a8392d
#include <Aris/Chunjee/adash>

;keeps processes locked to one window
DllCall("AllocConsole")

;update vcpkg
RunCMD("git pull","C:\dev\vcpkg")
If (!RunCMD.ExitCode)    ;updates vcpkg only on a good git pull
    RunCMD("C:\dev\vcpkg\bootstrap-vcpkg.bat","C:\dev\vcpkg")

;clean previous install
try DirDelete(A_ScriptDir "\build\",1)



;build wolfssl
wolfsslFeatures := adash.join([
    ; "asio", ;previously worked, currently introduces a build failure
    ; "curve25519-blinding"   ;not needed
    "dtls",
    "quic",
    ; "secret-callback"   ;not needed
])

wolfssl := "wolfssl[" wolfsslFeatures "]"
If RunWait("vcpkg install " wolfssl " --x-install-root=build --recurse",A_ScriptDir)
    throw("building WolfSSL failed")



;build libcurl
curlFeatures := adash.join([
    "brotli",
    "c-ares",
    "gnutls",
    "gsasl",
    ; "gssapi",   ;unsupported
    "http2",
    "httpsrr",  ;beta support until August 1 2025
    "idn",
    "idn2",
    "ldap",
    "mbedtls",
    "non-http",
    "openssl",  ;uses libressl overlay 
    "psl",
    "rtmp",
    "schannel",
    ; "sectransp",    ;unsupported
    "ssh",
    "ssl",
    "ssls-export",  ;beta support until August 1 2025
    "sspi",
    "tool",
    "websockets",
    "winidn",
    ; "winldap",  ;Obsolete. Use feature 'ldap' instead.
    ; "winssl",    ;Legacy name for schannel
    "wolfssl",
    "zstd"
])

libcurl := "curl[" curlFeatures "]:x64-windows"
If RunWait("vcpkg install " libcurl " --overlay-ports=overlays\openssl --x-install-root=build --recurse --clean-after-build",A_ScriptDir)
    throw("building libcurl failed") 



;build libmagic
libmagicFeatures := adash.join([
    "bzip2",
    "lzma",
    "zlib",
    "zstd"
])

libmagic := "libmagic[" libmagicFeatures "]"
If RunWait("vcpkg install " libmagic " --x-install-root=build", A_ScriptDir)
    throw("building libmagic failed")

;clear old installed files now that the builds are succesful
FileDelete(A_ScriptDir "\bin\*.dll")
FileDelete(A_ScriptDir "\bin\*.mgc")

;install all built files
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\*.dll",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\share\misc\*.mgc",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\bin\*.dll",A_ScriptDir "\bin",1)