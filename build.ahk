#Requires AutoHotkey v2.0
#include "*i <Aris\SKAN\RunCMD>" ; SKAN/RunCMD@9a8392d

;update vcpkg
RunCMD("git pull","C:\dev\vcpkg")
If (!RunCMD.ExitCode)    ;updates vcpkg only on a good git pull
    RunCMD("C:\dev\vcpkg\bootstrap-vcpkg.bat","C:\dev\vcpkg")

;clean previous install
try DirDelete(A_ScriptDir "\build\",1)


;build wolfssl
wolfssl := "wolfssl[dtls,quic]"
If RunWait("vcpkg install " wolfssl " --x-install-root=build --recurse",A_ScriptDir)
    throw("building WolfSSL failed")

;build libcurl
libcurl := "curl[brotli,c-ares,gnutls,gsasl,http2,idn,idn2,ldap,mbedtls,non-http,openssl,psl,rtmp,schannel,ssh,ssl,sspi,tool,websockets,winidn,wolfssl,zstd]:x64-windows"
If RunWait("vcpkg install " libcurl " --overlay-ports=overlays\openssl --x-install-root=build --recurse --clean-after-build",A_ScriptDir)
    throw("building libcurl failed")

;build libmagic
libmagic := "libmagic[bzip2,lzma,zlib,zstd]"
If RunWait("vcpkg install " libmagic " --x-install-root=build", A_ScriptDir)
    throw("building libmagic failed")


;install all built files
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\*.dll",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\share\misc\*.mgc",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\bin\*.dll",A_ScriptDir "\bin",1)


