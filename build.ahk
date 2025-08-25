#Requires AutoHotkey v2.0
#include "*i <Aris\SKAN\RunCMD>" ; SKAN/RunCMD@9a8392d
#include <Aris/Chunjee/adash>

;keeps processes locked to one window
DllCall("AllocConsole")
buildlog := FileOpen(A_ScriptDir "\build.log","w")

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

vcpkgFlags := adash.join([
    "--x-install-root=build",
    "--recurse"
],A_Space)

vcpkgCmd := "vcpkg install " wolfssl " " vcpkgFlags
buildlog.WriteLine(vcpkgCmd)

If RunWait(vcpkgCmd,A_ScriptDir)
    throw("building WolfSSL failed")



;build libcurl
curlFeatures := adash.join([
    "brotli",
    "c-ares",
    "gnutls",
    "gsasl",
    ; "gssapi",   ;unsupported
    "http2",
    ; "http3",    ;currently incompatible with multi-ssl
    "httpsrr",
    "idn",
    "idn2",
    "ldap",
    "mbedtls",
    "non-http",
    "openssl",  ;uses libressl overlay 
    "psl",
    "rtmp",
    ; "sectransp",    ;unsupported
    "ssh",
    "ssl",
    "ssls-export",
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

vcpkgFlags := adash.join([
    "--overlay-ports=overlays\openssl",
    "--x-install-root=build",
    "--recurse",
    ; "--clean-after-build"
],A_Space)

vcpkgCmd := "vcpkg install " libcurl " " vcpkgFlags
buildlog.WriteLine(vcpkgCmd)

If RunWait(vcpkgCmd,A_ScriptDir)
    throw("building libcurl failed") 
buildlog.WriteLine(vcpkgCmd)



;build libmagic
libmagicFeatures := adash.join([
    "bzip2",
    "lzma",
    "zlib",
    "zstd"
])

libmagic := "libmagic[" libmagicFeatures "]"

vcpkgFlags := adash.join([
    "--x-install-root=build"
],A_Space)

vcpkgCmd := "vcpkg install " libmagic " " vcpkgFlags

If RunWait(vcpkgCmd, A_ScriptDir)
    throw("building libmagic failed")

buildlog.WriteLine(vcpkgCmd)

;clear old installed files now that the builds are succesful
FileDelete(A_ScriptDir "\bin\*.dll")
FileDelete(A_ScriptDir "\bin\*.mgc")

;install all built files
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\*.dll",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\curl.exe",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\share\misc\*.mgc",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\bin\*.dll",A_ScriptDir "\bin",1)
buildlog.Close()