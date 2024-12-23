DEL bin\*.dll

vcpkg remove curl --overlay-ports=C:\Projects\LibQurl\overlays\openssl --x-install-root=C:\Projects\LibQurl\bin --recurse
vcpkg remove wolfssl --x-install-root=C:\Projects\LibQurl\bin --recurse

vcpkg install wolfssl[asio,dtls,quic] --x-install-root=C:\Projects\LibQurl\bin --recurse
vcpkg install curl[brotli,c-ares,gnutls,gsasl,http2,idn,idn2,ldap,mbedtls,non-http,openssl,psl,schannel,ssh,ssl,sspi,tool,websockets,winidn,wolfssl,zstd]:x64-windows --x-install-root=C:\Projects\LibQurl\bin --recurse

COPY C:\Projects\LibQurl\bin\x64-windows\tools\curl\*.dll bin\