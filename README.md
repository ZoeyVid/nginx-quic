# nginx-quic
Docker image for Nginx + HTTP/3

Requires: `zlib luajit pcre libstdc++ yajl libxml2 libxslt perl libcurl lua5.1-libs` and libmodsecurity <br>
Please add: `/usr/local/nginx/lib/lua/?.lua;;` to the http part of your nginx.conf.
If you use the tar files, please move the `libmodsecurity.so.3` file to `/usr/local/modsecurity/lib/libmodsecurity.so.3`
