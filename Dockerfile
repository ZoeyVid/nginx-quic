FROM alpine:3.18.4 as build
ARG BUILD

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib
ARG NGINX_VER=1.25.3

WORKDIR /src
# Requirements
RUN apk add --no-cache ca-certificates build-base patch cmake git libtool autoconf automake \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev perl-dev curl-dev lmdb-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev
# Openssl
RUN git clone --recursive https://github.com/quictls/openssl --branch openssl-3.1.4+quic /src/openssl
# modsecurity
RUN git clone --recursive https://github.com/SpiderLabs/ModSecurity /src/ModSecurity && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && \
    /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3
# Nginx
RUN wget https://nginx.org/download/nginx-"$NGINX_VER".tar.gz -O - | tar xzC /src && \
    mv /src/nginx-"$NGINX_VER" /src/nginx && \
    wget https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.25.1%2B.patch -O /src/nginx/1.patch && \
    wget https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-1.23.0-resolver_conf_parsing.patch -O /src/nginx/2.patch && \
    sed -i "s|nginx/|NPMplus/|g" /src/nginx/src/core/nginx.h && \
    sed -i "s|Server: nginx|Server: NPMplus|g" /src/nginx/src/http/ngx_http_header_filter_module.c && \
    sed -i "s|<hr><center>nginx</center>|<hr><center>NPMplus</center>|g" /src/nginx/src/http/ngx_http_special_response.c && \
    cd /src/nginx && \
    patch -p1 </src/nginx/1.patch && \
    patch -p1 </src/nginx/2.patch && \
    rm /src/nginx/*.patch && \
# modules
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \
    git clone --recursive https://github.com/openresty/headers-more-nginx-module /src/headers-more-nginx-module && \
#    git clone --recursive https://github.com/nginx-modules/ngx_http_limit_traffic_ratefilter_module /src/ngx_http_limit_traffic_ratefilter_module && \
    git clone --recursive https://github.com/nginx/njs /src/njs && \
    git clone --recursive https://github.com/vision5/ngx_devel_kit /src/ngx_devel_kit && \
    git clone --recursive https://github.com/openresty/lua-nginx-module /src/lua-nginx-module && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx /src/ModSecurity-nginx && \
    git clone --recursive https://github.com/openresty/lua-resty-core /src/lua-resty-core && \
    git clone --recursive https://github.com/openresty/lua-resty-lrucache /src/lua-resty-lrucache && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module /src/ngx_http_geoip2_module && \
# Configure
    cd /src/nginx && \
    /src/nginx/configure \
    --build=${BUILD} \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-libatomic \
    --with-pcre \
    --with-pcre-jit \
    --without-poll_module \
    --without-select_module \
    --with-openssl="/src/openssl" \
#    --with-openssl-opt="no-ssl3 no-ssl3-method no-weak-ssl-ciphers" \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_ssl_module \
    --with-http_perl_module \
    --with-http_geoip_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/headers-more-nginx-module \
#    --add-module=/src/ngx_http_limit_traffic_ratefilter_module \
    --add-module=/src/njs/nginx \
    --add-module=/src/ngx_devel_kit \
    --add-module=/src/lua-nginx-module \
    --add-module=/src/ModSecurity-nginx \
    --add-module=/src/ngx_http_geoip2_module && \
# Build & Install
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/nginx/sbin/nginx && \
    cd /src/lua-resty-core && \
    make install PREFIX=/usr/local/nginx && \
    cd /src/lua-resty-lrucache && \
    make install PREFIX=/usr/local/nginx

FROM python:3.12.0-alpine3.18
COPY --from=build /usr/local/nginx                               /usr/local/nginx
COPY --from=build /usr/local/lib/perl5                           /usr/local/lib/perl5
COPY --from=build /usr/lib/perl5/core_perl/perllocal.pod         /usr/lib/perl5/core_perl/perllocal.pod
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
RUN apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt perl libcurl lmdb lua5.1-libs geoip libmaxminddb-libs && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
