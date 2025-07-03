# nginx-quic
Docker image for nginx with HTTP/3-module - used as base image for NPMplus, it also contains libmodsec, some patches and some modules (including lua), you can find the all links in the Dockerfile. The python-version/python-latest build also contains python and certbot.

Requires: `zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs libprotobuf openssl` <br>
Please add: `lua_package_path "/usr/local/nginx/lib/lua/?.lua;;";` to the http part of your `nginx.conf`. <br>
If you use the tar files, please move the files in the lib folder to the `/usr/local/lib` folder.
