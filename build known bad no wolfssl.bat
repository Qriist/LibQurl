vcpkg remove curl --overlay-ports=overlays\openssl --x-install-root=build --recurse

vcpkg install curl[brotli,c-ares,gnutls,gsasl,http2,idn,idn2,ldap,mbedtls,non-http,openssl,psl,rtmp,schannel,ssh,ssl,sspi,tool,websockets,winidn,zstd]:x64-windows --overlay-ports=overlays\openssl --x-install-root=build --recurse

COPY C:\Projects\LibQurl\build\x64-windows\tools\curl\*.dll bin\ /Y