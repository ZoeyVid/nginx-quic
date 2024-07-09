# syntax=docker/dockerfile:labs
FROM alpine:3.20.1 AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

ARG NGINX_VER=1.27.2
ARG OPENSSL_VER=openssl-3.1.5+quic
ARG MODSEC_VER=v3.0.12

ARG DTR_VER=1.25.1
ARG RCP_VER=1.27.0

ARG NB_VER=master
ARG NF_VER=master
ARG HMNM_VER=v0.37
ARG NJS_VER=0.8.5
ARG NDK_VER=v0.3.3
ARG LNM_VER=v0.10.26
ARG MODSECNGX_VER=v1.0.3
ARG LRC_VER=v0.1.28
ARG LRL_VER=v0.13
ARG NHG2M_VER=3.4

WORKDIR /src
# Requirements
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates build-base patch cmake git libtool autoconf automake perl \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev curl-dev lmdb-dev libfuzzy2-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev
# Openssl
RUN git clone https://github.com/quictls/openssl --branch "$OPENSSL_VER" /src/openssl
# modsecurity
RUN git clone --recursive https://github.com/owasp-modsecurity/ModSecurity --branch "$MODSEC_VER" /src/ModSecurity && \
    sed -i "s|SecRuleEngine .*|SecRuleEngine On|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|^SecAudit|#SecAudit|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|unicode.mapping|/usr/local/nginx/conf/conf.d/include/unicode.mapping|g" /src/ModSecurity/modsecurity.conf-recommended && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && \
    /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3
# Nginx
RUN wget -q https://freenginx.org/download/freenginx-"$NGINX_VER".tar.gz -O - | tar xzC /src && \
    mv /src/freenginx-"$NGINX_VER" /src/freenginx && \
    wget -q https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_"$DTR_VER"%2B.patch -O /src/freenginx/1.patch && \
    wget -q https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-"$RCP_VER"-resolver_conf_parsing.patch -O /src/freenginx/2.patch && \
    sed -i "s|freenginx|NPMplus|g" /src/freenginx/src/core/nginx.h && \
    cd /src/freenginx && \
    patch -p1 </src/freenginx/1.patch && \
    patch -p1 </src/freenginx/2.patch && \
    rm /src/freenginx/*.patch && \
# modules
    git clone --recursive https://github.com/google/ngx_brotli --branch "$NB_VER" /src/ngx_brotli && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex --branch "$NF_VER" /src/ngx-fancyindex && \
    git clone --recursive https://github.com/openresty/headers-more-nginx-module --branch "$HMNM_VER" /src/headers-more-nginx-module && \
    git clone --recursive https://github.com/nginx/njs --branch "$NJS_VER" /src/njs && \
    git clone --recursive https://github.com/vision5/ngx_devel_kit --branch "$NDK_VER" /src/ngx_devel_kit && \
    git clone --recursive https://github.com/openresty/lua-nginx-module --branch "$LNM_VER" /src/lua-nginx-module && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx --branch "$MODSECNGX_VER" /src/ModSecurity-nginx && \
    git clone --recursive https://github.com/openresty/lua-resty-core --branch "$LRC_VER" /src/lua-resty-core && \
    git clone --recursive https://github.com/openresty/lua-resty-lrucache --branch "$LRL_VER" /src/lua-resty-lrucache && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module --branch "$NHG2M_VER" /src/ngx_http_geoip2_module
# Configure
RUN cd /src/freenginx && \
    /src/freenginx/configure \
    --build=freenginx \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-libatomic \
    --with-pcre \
    --with-pcre-jit \
    --with-openssl="/src/openssl" \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_geoip_module \
    --with-stream_realip_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_ssl_module \
    --with-http_geoip_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_geoip_module \
    --with-http_sub_module \
    --with-http_stub_status_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/headers-more-nginx-module \
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
    make -j "$(nproc)" install PREFIX=/usr/local/nginx && \
    cd /src/lua-resty-lrucache && \
    make -j "$(nproc)" install PREFIX=/usr/local/nginx && \
    perl /src/openssl/configdata.pm --dump

FROM alpine:3.20.1
COPY --from=build /usr/local/nginx                               /usr/local/nginx
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
COPY --from=build /src/ModSecurity/unicode.mapping               /usr/local/nginx/conf/conf.d/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended  /usr/local/nginx/conf/conf.d/include/modsecurity.conf.example
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
