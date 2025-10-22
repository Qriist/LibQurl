#Requires AutoHotkey v2.0
#include "*i <Aris\SKAN\RunCMD>" ; SKAN/RunCMD@9a8392d
#include <Aris/Chunjee/adash>
#include <Aris/G33kDude/cJson>

;keeps processes locked to one window
DllCall("AllocConsole")
buildlog := FileOpen(A_ScriptDir "\build.log","w")

libArr := ["wolfssl","curl","libmagic"]
portsDir := "C:\dev\vcpkg\ports"
oldVerMap := vcpkgPortVersions(libArr,portsDir)
; for k,v in verMap
    ; msgbox k
;update vcpkg
RunCMD("git pull","C:\dev\vcpkg")
If (!RunCMD.ExitCode)    ;updates vcpkg only on a good git pull
    RunCMD("C:\dev\vcpkg\bootstrap-vcpkg.bat","C:\dev\vcpkg")
newVerMap := vcpkgPortVersions(libArr,portsDir,oldVerMap)
; msgbox oldVerMap.count "`n" newVerMap.count
;clean previous install
try DirDelete(A_ScriptDir "\build\",1)



;build wolfssl
wolfsslFeatures := libraryFeatureFlags("wolfssl",1)
wolfssl := "wolfssl[" wolfsslFeatures "]"

vcpkgFlags := adash.join([
    "--x-install-root=build",
    "--recurse",
    "--clean-after-build"
],A_Space)

vcpkgCmd := "vcpkg install " wolfssl " " vcpkgFlags
buildlog.WriteLine(vcpkgCmd)

If RunWait(vcpkgCmd,A_ScriptDir)
    throw("building WolfSSL failed")



;build libcurl
curlFeatures := libraryFeatureFlags("libcurl",1)
libcurl := "curl[" curlFeatures "]:x64-windows" 

vcpkgFlags := adash.join([
    "--overlay-ports=overlays\openssl",
    "--x-install-root=build",
    "--recurse",
    "--clean-after-build"
],A_Space)

vcpkgCmd := "vcpkg install " libcurl " " vcpkgFlags
buildlog.WriteLine(vcpkgCmd)

If RunWait(vcpkgCmd,A_ScriptDir)
    throw("building libcurl failed") 
buildlog.WriteLine(vcpkgCmd)



;build libmagic
libmagicFeatures := libraryFeatureFlags("libmagic",1)
libmagic := "libmagic[" libmagicFeatures "]"

vcpkgFlags := adash.join([
    "--x-install-root=build",
    "--recurse",
    "--clean-after-build"
],A_Space)

vcpkgCmd := "vcpkg install " libmagic " " vcpkgFlags

If RunWait(vcpkgCmd, A_ScriptDir)
    throw("building libmagic failed")

buildlog.WriteLine(vcpkgCmd)

;clear old installed files now that the builds are succesful
FileDelete(A_ScriptDir "\bin\curl.exe")
FileDelete(A_ScriptDir "\bin\*.dll")
FileDelete(A_ScriptDir "\bin\*.mgc")

;install all built files
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\*.dll",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\curl\curl.exe",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\share\misc\*.mgc",A_ScriptDir "\bin",1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\bin\*.dll",A_ScriptDir "\bin",1)
buildlog.Close()



libraryFeatureFlags(requestedLibrary,join?){
    switch requestedLibrary {
        case "wolfssl":
            ret := [
                ; "asio", ;previously worked, currently introduces a build failure
                ; "curve25519-blinding"   ;not needed
                "dtls",
                "quic",
                ; "secret-callback"   ;not needed
            ]
        case "curl","libcurl":
            ret := [
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
            ]    
        case "libmagic":
            ret := [
                "bzip2",
                "lzma",
                "zlib",
                "zstd"
            ]
        default:
            MsgBox "unknown library requested"
            ExitApp
    }

    if join
        return adash.join(ret)
    return ret
}

vcpkgPortVersions(libArr,portsDir,oldVerMap?){
    verMap := Map()
    for k,v in libArr {
        lib := v

        ;prepare each tool's command line *before* updating vcpkg so versions can be compared
        features := libraryFeatureFlags(lib,1)
        libcmd := lib "[" features "]"
        
        ;query current version numbers for curl/wolfssl/libmagic + each flag port
        ports := StrSplit(RunCMD("vcpkg depend-info " libcmd ":x64-windows"),"`n","`r")
        ports := StrSplit(ports[ports.length],":"," ")[2]
        ports := StrSplit(ports,","," ")
        ports.Push(lib)

        for k,v in ports{
            port := v
            (port!="openssl"?"":port:="libressl")   ;manual overlay handling for libressl because lazy
            portMap := JSON.Load(FileRead(portsDir "\" port "\vcpkg.json"))

            if portMap.has("version")
                verMap[port] := portMap["version"]
            else if portMap.has("version-semver")
                verMap[port] := portMap["version-semver"]
            else if portMap.has("version-string")
                verMap[port] := portMap["version-string"]
            else if portMap.has("version-date")
                verMap[port] := portMap["version-date"]
            else {
                msgbox port "!"
                continue   
            }

            If portMap.has("port-version"){
                verMap[port] .= "#" portMap["port-version"]
            }
                
        }
    }
    ;return the freshly made map
    If !IsSet(oldVerMap?)
        return verMap

    ;return only updated elements
    newVerMap := Map()
    for k,v in verMap {
        if (oldVerMap.has(k))   ;regular bumped version
        && (oldVerMap[k] != v)
            newVerMap[k] := v 
        else if (!oldVerMap.has(k)) ;additional new library
            newVerMap[k] := v
    }
    return newVerMap
}