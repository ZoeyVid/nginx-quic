FROM alpine:3.18.2 as build
ARG BUILD

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib
ARG NGINX_VER=1.25.1

WORKDIR /src
# Requirements
RUN apk add --no-cache ca-certificates build-base patch cmake git mercurial libtool autoconf automake \
    libatomic_ops-dev zlib-dev luajit-dev pcre-dev linux-headers yajl-dev libxml2-dev perl-dev lua5.1-dev
# Openssl
RUN git clone --recursive https://github.com/quictls/openssl --branch openssl-3.1.0+quic+locks /src/openssl
RUN cd /src/openssl && \
    /src/openssl/Configure linux-"$(uname -m)" no-ssl3 no-ssl3-method && \
    make -j "$(nproc)"
# modsecurity
RUN git clone --recursive https://github.com/SpiderLabs/ModSecurity /src/ModSecurity && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && \
    /src/ModSecurity/configure && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3
# Nginx
RUN wget https://nginx.org/download/nginx-"$NGINX_VER".tar.gz -O - | tar xzC /src && \
    mv /src/nginx-"$NGINX_VER" /src/nginx && \
    wget https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.25.1%2B.patch -O /src/nginx/1.patch && \
    wget https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-1.23.0-resolver_conf_parsing.patch -O /src/nginx/2.patch && \
#    wget https://github.com/angristan/nginx-autoinstall/raw/master/patches/nginx_hpack_push_with_http3.patch -O /src/nginx/3.patch && \
#    sed -i "s|nginx/|nginx-proxy-manager/|g" /src/nginx/src/core/nginx.h && \
#    sed -i "s|Server: nginx|Server: nginx-proxy-manager|g" /src/nginx/src/http/ngx_http_header_filter_module.c && \
#    sed -i "s|<hr><center>nginx</center>|<hr><center>nginx-proxy-manager</center>|g" /src/nginx/src/http/ngx_http_special_response.c && \
    cd /src/nginx && \
    patch -p1 </src/nginx/1.patch && \
    patch -p1 </src/nginx/2.patch && \
#    patch -p1 </src/nginx/3.patch && \
    rm /src/nginx/*.patch && \
# modules
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_security_headers /src/ngx_security_headers && \
#    git clone --recursive https://github.com/nginx-modules/ngx_http_limit_traffic_ratefilter_module /src/ngx_http_limit_traffic_ratefilter_module && \
    hg clone http://hg.nginx.org/njs /src/njs && \
    git clone --recursive https://github.com/vision5/ngx_devel_kit /src/ngx_devel_kit && \
    git clone --recursive https://github.com/openresty/lua-nginx-module /src/lua-nginx-module && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx /src/ModSecurity-nginx && \
    git clone --recursive https://github.com/openresty/lua-resty-core /src/lua-resty-core && \
    git clone --recursive https://github.com/openresty/lua-resty-lrucache /src/lua-resty-lrucache && \
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
    --with-ld-opt="-L/src/openssl/build/lib" \
    --with-cc-opt="-I/src/openssl/build/include" \
#    --with-mail \
#    --with-mail_ssl_module \
    --with-stream \
#    --with-stream_ssl_module \
#    --with-stream_realip_module \
#    --with-stream_ssl_preread_module \
    --with-http_v2_module \
#    --with-http_v2_hpack_enc \
    --with-http_v3_module \
    --with-http_ssl_module \
    --with-http_perl_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/ngx_security_headers \
#    --add-module=/src/ngx_http_limit_traffic_ratefilter_module \
    --add-module=/src/njs/nginx \
    --add-module=/src/ngx_devel_kit \
    --add-module=/src/lua-nginx-module \
    --add-module=/src/ModSecurity-nginx && \
# Build & Install
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/nginx/sbin/nginx && \
    cd /src/lua-resty-core && \
    make install PREFIX=/usr/local/nginx && \
    cd /src/lua-resty-lrucache && \
    make install PREFIX=/usr/local/nginx

FROM python:3.11.4-alpine3.18
COPY --from=build /usr/local/nginx                               /usr/local/nginx
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
RUN apk add --no-cache ca-certificates tzdata zlib luajit pcre libstdc++ yajl libxml2 perl lua5.1-libs && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
