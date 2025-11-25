# syntax=docker/dockerfile:labs
FROM alpine:3.22.2 AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

ARG NGINX_VER=release-1.29.3
ARG MODSEC_VER=v3.0.14

ARG DTR_VER=1.29.2
ARG RCP_VER=1.29.2

ARG NB_VER=master
ARG NUB_VER=main
ARG ZNM_VER=master
ARG NF_VER=master
ARG HMNM_VER=v0.39
ARG NDK_VER=v0.3.4
ARG LNM_VER=v0.10.29

ARG NJS_VER=0.9.4
ARG NAL_VER=master
ARG VTS_VER=v0.2.4
ARG NNTLM_VER=master
ARG MODSECNGX_VER=v1.0.4
ARG NHG2M_VER=3.4

ARG LRC_VER=v0.1.32
ARG LRL_VER=v0.15

ARG OT_VER=v1.24.0

# -fPIE -pie / -fPIC -shared
ARG FLAGS
ARG CC=clang
ARG CFLAGS="$FLAGS -m64 -O2 -pipe -flto=thin -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG CXX=clang++
ARG CXXFLAGS="$FLAGS -m64 -O2 -pipe -flto=thin -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG LDFLAGS="-fuse-ld=lld -m64 -Wl,-s -Wl,-O1 -Wl,--gc-sections -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--sort-common -Wl,-z,pack-relative-relocs"

WORKDIR /src
COPY attachment.patch /src/attachment.patch
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates build-base clang lld cmake ninja git libtool autoconf automake bash \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev curl-dev lmdb-dev libfuzzy2-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev gtest-dev benchmark-dev protobuf-dev openldap-dev

# ModSecurity
RUN git clone --depth 1 --shallow-submodules --recurse-submodules https://github.com/owasp-modsecurity/ModSecurity --branch "$MODSEC_VER" /src/ModSecurity && \
    cd /src/ModSecurity && \
    sed -i "s|SecRuleEngine .*|SecRuleEngine On|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|^SecAudit|#SecAudit|g" /src/ModSecurity/modsecurity.conf-recommended && \
    sed -i "s|unicode.mapping|/usr/local/nginx/conf/conf.d/include/unicode.mapping|g" /src/ModSecurity/modsecurity.conf-recommended && \
    /src/ModSecurity/build.sh && \
    /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j "$(nproc)" install

# Download nginx
RUN git clone --depth 1 https://github.com/nginx/nginx --branch "$NGINX_VER" /src/nginx && \
    cd /src/nginx && \
    wget -q https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/refs/heads/master/nginx__dynamic_tls_records_"$DTR_VER"%2B.patch -O /src/nginx/1.patch && \
    wget -q https://raw.githubusercontent.com/openresty/openresty/refs/heads/master/patches/nginx/"$RCP_VER"/nginx-"$RCP_VER"-resolver_conf_parsing.patch -O /src/nginx/2.patch && \
    sed -i "s|nginx/|NPMplus/|g" /src/nginx/src/core/nginx.h && \
    sed -i "s|Server: nginx|Server: NPMplus|g" /src/nginx/src/http/ngx_http_header_filter_module.c && \
    sed -i "/<hr><center>/d" /src/nginx/src/http/ngx_http_special_response.c && \
    git diff && \
    git apply /src/nginx/1.patch && \
    git apply /src/nginx/2.patch && \
    rm -v /src/nginx/*.patch && \
# modules
    git clone --depth 1 --shallow-submodules --recurse-submodules https://github.com/google/ngx_brotli --branch "$NB_VER" /src/ngx_brotli && \
    git clone --depth 1 https://github.com/clyfish/ngx_unbrotli --branch "$NUB_VER" /src/ngx_unbrotli && \
    git clone --depth 1 https://github.com/tokers/zstd-nginx-module --branch "$ZNM_VER" /src/zstd-nginx-module && \
    git clone --depth 1 https://github.com/Zoey2936/ngx-fancyindex --branch "$NF_VER" /src/ngx-fancyindex && \
    git clone --depth 1 https://github.com/openresty/headers-more-nginx-module --branch "$HMNM_VER" /src/headers-more-nginx-module && \
    git clone --depth 1 https://github.com/vision5/ngx_devel_kit --branch "$NDK_VER" /src/ngx_devel_kit && \
    git clone --depth 1 https://github.com/openresty/lua-nginx-module --branch "$LNM_VER" /src/lua-nginx-module && \
    git clone --depth 1 https://github.com/nginx/njs --branch "$NJS_VER" /src/njs && \
    git clone --depth 1 https://github.com/kvspb/nginx-auth-ldap --branch "$NAL_VER" /src/nginx-auth-ldap && \
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts --branch "$VTS_VER" /src/nginx-module-vts && \
    git clone --depth 1 https://github.com/gabihodoroaga/nginx-ntlm-module --branch "$NNTLM_VER" /src/nginx-ntlm-module && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx --branch "$MODSECNGX_VER" /src/ModSecurity-nginx && \
    git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module --branch "$NHG2M_VER" /src/ngx_http_geoip2_module

# build_brotli.sh for ngx_unbrotli
RUN cd /src/ngx_unbrotli && /src/ngx_unbrotli/build_brotli.sh

# Configure nginx
RUN cd /src/nginx && \
    /src/nginx/auto/configure \
    --build=nginx \
    --with-debug \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-libatomic \
    --with-pcre \
    --with-pcre-jit \
    --without-select_module \
    --without-poll_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_addition_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx_unbrotli \
    --add-module=/src/zstd-nginx-module \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/headers-more-nginx-module \
    --add-module=/src/ngx_devel_kit \
    --add-module=/src/lua-nginx-module \
    --with-http_geoip_module=dynamic \
    --with-stream_geoip_module=dynamic \
    --add-dynamic-module=/src/njs/nginx \
    --add-dynamic-module=/src/nginx-auth-ldap \
    --add-dynamic-module=/src/nginx-module-vts \
    --add-dynamic-module=/src/nginx-ntlm-module \
    --add-dynamic-module=/src/ModSecurity-nginx \
    --add-dynamic-module=/src/ngx_http_geoip2_module \
    --with-cc-opt="-Wno-sign-compare" \
    --with-ld-opt="-fuse-ld=lld -m64 -Wl,-s -Wl,-O1 -Wl,--gc-sections -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--sort-common -Wl,-z,pack-relative-relocs" && \
# Build nginx
    make -j "$(nproc)" install && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx && \
    git clone --depth 1 https://github.com/openresty/lua-resty-core --branch "$LRC_VER" /src/lua-resty-core && \
    cd /src/lua-resty-core && \
    make -j "$(nproc)" install LUA_LIB_DIR=/usr/local/share/lua/5.1 && \
    git clone --depth 1 https://github.com/openresty/lua-resty-lrucache --branch "$LRL_VER" /src/lua-resty-lrucache && \
    cd /src/lua-resty-lrucache && \
    make -j "$(nproc)" install LUA_LIB_DIR=/usr/local/share/lua/5.1

# openappsec attachment
RUN git clone --depth 1 https://github.com/openappsec/attachment /src/attachment && \
    cd /src/attachment && \
    git apply /src/attachment.patch && \
    rm -v /src/attachment.patch && \
    cmake /src/attachment -G Ninja && \
    ninja && \
    mv -v /src/attachment/attachments/nginx/ngx_module/libngx_module.so /usr/local/nginx/modules/libngx_module.so

# OpenTelemetry lib
ARG CC=gcc
#-flto -fzero-init-padding-bits=all
ARG CFLAGS="$FLAGS -Wtrampolines -Wbidi-chars=any -O2 -pipe -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG CXX=g++
#-flto -fzero-init-padding-bits=all
ARG CXXFLAGS="$FLAGS -Wtrampolines -Wbidi-chars=any -O2 -pipe -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG LDFLAGS="-Wl,-s -Wl,-O1 -Wl,--gc-sections -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--sort-common -Wl,-z,pack-relative-relocs"
RUN git clone --depth 1 https://github.com/open-telemetry/opentelemetry-cpp --branch "$OT_VER" /src/opentelemetry-cpp && \
    cd /src/opentelemetry-cpp && \
    cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DWITH_OTLP_HTTP=ON -G Ninja && \
    ninja install

# OpenTelemetry module
ARG CC=clang
ARG CFLAGS="$FLAGS -m64 -O2 -pipe -flto=thin -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG CXX=clang++
ARG CXXFLAGS="$FLAGS -m64 -O2 -pipe -flto=thin -funroll-loops -ffunction-sections -fdata-sections -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS=1 -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST -Wformat=2 -Werror=format-security"
ARG LDFLAGS="-fuse-ld=lld -m64 -Wl,-s -Wl,-O1 -Wl,--gc-sections -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--sort-common -Wl,-z,pack-relative-relocs"
RUN git clone --depth 1 https://github.com/open-telemetry/opentelemetry-cpp-contrib /src/opentelemetry-cpp-contrib && \
    cd /src/opentelemetry-cpp-contrib/instrumentation/nginx && \
    cmake -G Ninja && \
    ninja && \
    mv -v /src/opentelemetry-cpp-contrib/instrumentation/nginx/otel_ngx_module.so /usr/local/nginx/modules/otel_ngx_module.so

# strip files
RUN strip -s /usr/local/nginx/sbin/nginx && \
    find /usr/local/nginx/modules -name "*.so" -exec strip -s {} \; && \
    strip -s /src/ModSecurity/src/.libs/libmodsecurity.so.3 && \
    strip -s /src/opentelemetry-cpp/libopentelemetry_proto.so && \
    strip -s /src/attachment/core/shmem_ipc/libosrc_shmem_ipc.so && \
    strip -s /src/attachment/core/compression/libosrc_compression_utils.so && \
    strip -s /src/attachment/attachments/nginx/nginx_attachment_util/libosrc_nginx_attachment_util.so

FROM alpine:3.22.2
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY --from=build /usr/local/nginx                                                                         /usr/local/nginx
COPY --from=build /usr/local/share/lua/5.1                                                                 /usr/local/share/lua/5.1
COPY --from=build /src/ModSecurity/src/.libs/libmodsecurity.so.3                                           /usr/local/lib/libmodsecurity.so.3
COPY --from=build /src/ModSecurity/unicode.mapping                                                         /usr/local/nginx/conf/conf.d/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended                                            /usr/local/nginx/conf/conf.d/include/modsecurity.conf.example
COPY --from=build /src/opentelemetry-cpp/libopentelemetry_proto.so                                         /usr/local/lib/libopentelemetry_proto.so
COPY --from=build /src/attachment/core/shmem_ipc/libosrc_shmem_ipc.so                                      /usr/local/lib/libosrc_shmem_ipc.so
COPY --from=build /src/attachment/core/compression/libosrc_compression_utils.so                            /usr/local/lib/libosrc_compression_utils.so
COPY --from=build /src/attachment/attachments/nginx/nginx_attachment_util/libosrc_nginx_attachment_util.so /usr/local/lib/libosrc_nginx_attachment_util.so
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs libprotobuf openldap openssl && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
