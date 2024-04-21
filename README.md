# nginx-quic
Docker image for Nginx + HTTP/3 - used as base image for NPMplus, it also contains libmodsec and some modules (including lua). The python-version/python-latest build also contains python.

Requires: `zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs` and libmodsecurity <br>
Please add: `lua_package_path "/usr/local/nginx/lib/lua/?.lua;;";` to the http part of your nginx.conf.
If you use the tar files, please move the `nginx/libmodsecurity.so.3` file to `/usr/local/modsecurity/lib/libmodsecurity.so.3`
