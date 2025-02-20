# syntax=docker/dockerfile:labs
FROM alpine:3.21.3 AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

ARG NGINX_VER=release-1.27.4
ARG MODSEC_VER=v3.0.13

ARG DTR_VER=1.27.4
ARG RCP_VER=1.27.1

ARG NB_VER=master
ARG NF_VER=master
ARG HMNM_VER=v0.38
ARG NJS_VER=0.8.9
ARG NDK_VER=v0.3.4
ARG LNM_VER=v0.10.28
ARG MODSECNGX_VER=v1.0.3
ARG LRC_VER=v0.1.31
ARG LRL_VER=v0.15
ARG NHG2M_VER=3.4
ARG NNTLM_VER=master

ARG LIBOQS_VER=0.12.0
ARG OQSPROVIDER_VER=0.8.0

ARG OT_VER=v1.19.0

WORKDIR /src
COPY attachment.patch /src/attachment.patch
# Requirements
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates build-base cmake ninja git libtool autoconf automake bash \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev curl-dev lmdb-dev libfuzzy2-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev gtest-dev benchmark-dev protobuf-dev && \
# ModSecurity
    git clone --recursive https://github.com/owasp-modsecurity/ModSecurity --branch "$MODSEC_VER" /src/ModSecurity && \
    cd /src/ModSecurity && \
    sed -i "s|SecRuleEngine .*|SecRuleEngine On|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|^SecAudit|#SecAudit|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|unicode.mapping|/usr/local/nginx/conf/conf.d/include/unicode.mapping|g" /src/ModSecurity/modsecurity.conf-recommended && \
    /src/ModSecurity/build.sh && \
    /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j "$(nproc)" install && \
# Nginx
    git clone https://github.com/nginx/nginx --branch "$NGINX_VER" /src/nginx && \
    cd /src/nginx && \
    wget -q https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_"$DTR_VER"%2B.patch -O /src/nginx/1.patch && \
    wget -q https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-"$RCP_VER"-resolver_conf_parsing.patch -O /src/nginx/2.patch && \
    sed -i "s|nginx/|NPMplus/|g" /src/nginx/src/core/nginx.h && \
    sed -i "s|Server: nginx|Server: NPMplus|g" /src/nginx/src/http/ngx_http_header_filter_module.c && \
    sed -i "/<hr><center>/d" /src/nginx/src/http/ngx_http_special_response.c && \
    git diff && \
    git apply /src/nginx/1.patch && \
    git apply /src/nginx/2.patch && \
    rm -v /src/nginx/*.patch && \
# modules
    git clone --recursive https://github.com/google/ngx_brotli --branch "$NB_VER" /src/ngx_brotli && \
    git clone https://github.com/aperezdc/ngx-fancyindex --branch "$NF_VER" /src/ngx-fancyindex && \
    git clone https://github.com/openresty/headers-more-nginx-module --branch "$HMNM_VER" /src/headers-more-nginx-module && \
    git clone https://github.com/nginx/njs --branch "$NJS_VER" /src/njs && \
    git clone https://github.com/vision5/ngx_devel_kit --branch "$NDK_VER" /src/ngx_devel_kit && \
    git clone https://github.com/openresty/lua-nginx-module --branch "$LNM_VER" /src/lua-nginx-module && \
    git clone https://github.com/openresty/lua-resty-core --branch "$LRC_VER" /src/lua-resty-core && \
    git clone https://github.com/openresty/lua-resty-lrucache --branch "$LRL_VER" /src/lua-resty-lrucache && \
    git clone https://github.com/leev/ngx_http_geoip2_module --branch "$NHG2M_VER" /src/ngx_http_geoip2_module && \
    git clone https://github.com/gabihodoroaga/nginx-ntlm-module --branch "$NNTLM_VER" /src/nginx-ntlm-module && \
# patch ModSecurity-nginx
    git clone https://github.com/SpiderLabs/ModSecurity-nginx --branch "$MODSECNGX_VER" /src/ModSecurity-nginx && \
    cd /src/ModSecurity-nginx && \
    wget -q https://patch-diff.githubusercontent.com/raw/owasp-modsecurity/ModSecurity-nginx/pull/320.patch -O /src/ModSecurity-nginx/1.patch && \
    git apply /src/ModSecurity-nginx/1.patch && \
    rm -v /src/ModSecurity-nginx/*.patch && \
# Configure
    cd /src/nginx && \
    /src/nginx/auto/configure \
    --build=nginx \
    --with-debug \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-libatomic \
    --with-pcre \
    --with-pcre-jit \
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
    --add-module=/src/ngx_http_geoip2_module \
    --add-module=/src/nginx-ntlm-module && \
# Build & Install
    make -j "$(nproc)" install && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx && \
    cd /src/lua-resty-core && \
    make -j "$(nproc)" install PREFIX=/usr/local/nginx && \
    cd /src/lua-resty-lrucache && \
    make -j "$(nproc)" install PREFIX=/usr/local/nginx && \
# openappsec attachment
    git clone https://github.com/openappsec/attachment /src/attachment && \
    cd /src/attachment && \
    patch -p1 </src/attachment.patch && \
    rm -v /src/attachment.patch && \
    cmake /src/attachment -G Ninja && \
    ninja install && \
# liboqs
    git clone https://github.com/open-quantum-safe/liboqs --branch "$LIBOQS_VER" /src/liboqs && \
    cd /src/liboqs && \
    cmake -G Ninja && \
    ninja install && \
# oqs-provider
    git clone https://github.com/open-quantum-safe/oqs-provider --branch "$OQSPROVIDER_VER" /src/oqs-provider && \
    cd /src/oqs-provider && \
    cmake -DOQS_KEM_ENCODERS=ON -G Ninja && \
    ninja && \
# OpenTelemetry lib
    git clone https://github.com/open-telemetry/opentelemetry-cpp --branch "$OT_VER" /src/opentelemetry-cpp && \
    cd /src/opentelemetry-cpp && \
    cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DWITH_OTLP_HTTP=ON -G Ninja && \
    ninja install && \
# OpenTelemetry module
    git clone https://github.com/open-telemetry/opentelemetry-cpp-contrib /src/opentelemetry-cpp-contrib && \
    cd /src/opentelemetry-cpp-contrib/instrumentation/nginx && \
    cmake -G Ninja && \
    ninja && \
# strip files
    strip -s /usr/local/nginx/sbin/nginx && \
    strip -s /src/oqs-provider/lib/oqsprovider.so && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3 && \
    strip -s /usr/local/lib/libopentelemetry_proto.so && \
    strip -s /src/opentelemetry-cpp-contrib/instrumentation/nginx/otel_ngx_module.so

FROM alpine:3.21.3
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY --from=build /usr/local/nginx                                                        /usr/local/nginx
COPY --from=build /src/oqs-provider/lib/oqsprovider.so                                    /usr/lib/ossl-modules/oqsprovider.so
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3                          /usr/local/lib/libmodsecurity.so.3
COPY --from=build /usr/local/lib/libopentelemetry_proto.so                                /usr/local/lib/libopentelemetry_proto.so
COPY --from=build /src/opentelemetry-cpp-contrib/instrumentation/nginx/otel_ngx_module.so /usr/local/lib/otel_ngx_module.so
COPY --from=build /usr/local/lib/libngx_module.so                                         /usr/local/lib/libngx_module.so
COPY --from=build /usr/local/lib/libosrc_shmem_ipc.so                                     /usr/local/lib/libosrc_shmem_ipc.so
COPY --from=build /usr/local/lib/libosrc_compression_utils.so                             /usr/local/lib/libosrc_compression_utils.so
COPY --from=build /usr/local/lib/libosrc_nginx_attachment_util.so                         /usr/local/lib/libosrc_nginx_attachment_util.so
COPY --from=build /src/ModSecurity/unicode.mapping                                        /usr/local/nginx/conf/conf.d/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended                           /usr/local/nginx/conf/conf.d/include/modsecurity.conf.example
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs libprotobuf openssl && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx && \
    sed -i "s|default = default_sect|default = default_sect\noqsprovider = oqsprovider_sect|g" /etc/ssl/openssl.cnf && \
    sed -i "s|\[default_sect\]|\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n|g" /etc/ssl/openssl.cnf

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
