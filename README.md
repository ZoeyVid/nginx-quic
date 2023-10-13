# nginx-quic
Docker image for Nginx + HTTP/3 - used as base image for NPMplus

Requires: `zlib luajit pcre libstdc++ yajl libxml2 libxslt perl libcurl lua5.1-libs geoip libmaxminddb-libs` and libmodsecurity <br>
Please add: `lua_package_path "/usr/local/nginx/lib/lua/?.lua;;";` to the http part of your nginx.conf.
If you use the tar files, please move the `nginx/perl5` folder to `/usr/local/lib/perl5`
If you use the tar files, please move the `nginx/perllocal.pod` file to `/usr/lib/perl5/core_perl/perllocal.pod`
If you use the tar files, please move the `nginx/libmodsecurity.so.3` file to `/usr/local/modsecurity/lib/libmodsecurity.so.3`
