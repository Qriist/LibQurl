@echo off
setlocal

:: Verify that VCPKG_ROOT is set
if "%VCPKG_ROOT%"=="" (
    echo ERROR: VCPKG_ROOT environment variable is not set.
    exit /b 1
)

:: Verify that VCPKG_ROOT exists
if not exist "%VCPKG_ROOT%" (
    echo ERROR: The directory specified in VCPKG_ROOT does not exist: %VCPKG_ROOT%
    exit /b 1
)

:: Save the current directory
set "saved_dir=%CD%"

:: Change to VCPKG_ROOT
cd /d "%VCPKG_ROOT%" || (
    echo ERROR: Failed to change to VCPKG_ROOT directory.
    exit /b 1
)
@echo off
git pull 
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& \""%VCPKG_ROOT%"\scripts\bootstrap.ps1\" %*}"

@echo on

cd /d "%saved_dir%"

endlocal


rmdir /S /Q build


vcpkg install wolfssl[dtls,quic] --x-install-root=build --recurse

vcpkg install curl[brotli,c-ares,gnutls,gsasl,http2,idn,idn2,ldap,mbedtls,non-http,openssl,psl,rtmp,schannel,ssh,ssl,sspi,tool,websockets,winidn,wolfssl,zstd]:x64-windows --overlay-ports=overlays\openssl --x-install-root=build --recurse --clean-after-build


COPY /Y C:\Projects\LibQurl\build\x64-windows\tools\curl\*.dll bin\