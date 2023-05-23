# nginx-quic
Docker image for Nginx + HTTP/3

Requires: `zlib luajit pcre libstdc++ yajl libxml2 lua5.1-libs`
Please add: `/usr/local/nginx/lib/lua/?.lua;;` to the http part of your nginx.conf (replace /usr/local/nginx with the patch where you installed the tar file to)
