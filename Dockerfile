FROM alpine:3.17.3 as build
ARG BUILD

# Requirements
RUN apk add --no-cache ca-certificates build-base patch cmake git mercurial perl \
    libatomic_ops-dev libatomic_ops-static zlib-dev zlib-static pcre-dev linux-headers && \
    mkdir /src && \
# Openssl
    cd /src && \
    git clone --recursive https://github.com/quictls/openssl /src/openssl && \
    cd /src/openssl && \
    /src/openssl/Configure && \
    make -j "$(nproc)" && \
# Nginx
    cd /src && \
    hg clone https://hg.nginx.org/nginx-quic -r "quic" /src/nginx && \
    wget https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.17.7%2B.patch -O /src/nginx/1.patch && \
    wget https://github.com/angristan/nginx-autoinstall/raw/master/patches/nginx_hpack_push_with_http3.patch -O /src/nginx/2.patch && \
    sed -i "s|nginx/|nginx-proxy-manager/|g" /src/nginx/src/core/nginx.h && \
    sed -i "s|Server: nginx|Server: nginx-proxy-manager|g" /src/nginx/src/http/ngx_http_header_filter_module.c && \
    sed -i "s|<hr><center>nginx</center>|<hr><center>nginx-proxy-manager</center>|g" /src/nginx/src/http/ngx_http_special_response.c && \
    cd /src/nginx && \
    patch -p1 </src/nginx/1.patch && \
    patch -p1 </src/nginx/2.patch && \
# njs
#    cd /src && \
#    hg clone http://hg.nginx.org/njs /src/njs && \
# nginx-upstream-fair
#    cd /src && \
#    git clone --recursive https://github.com/itoffshore/nginx-upstream-fair /src/nginx-upstream-fair && \
# testcookie
#    cd /src && \
#    git clone --recursive https://github.com/kyprizel/testcookie-nginx-module /src/testcookie-nginx-module && \
# ngx_http_js_challenge_module
#    cd /src && \
#    git clone --recursive https://github.com/dvershinin/ngx_http_js_challenge_module /src/ngx_http_js_challenge_module && \
# ngx-fancyindex
    cd /src && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \
# ngx_security_headers
    cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_security_headers /src/ngx_security_headers && \
# ngx_brotli
    cd /src && \
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \
# Configure
    cd /src/nginx && \
    /src/nginx/auto/configure \
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
    --with-ld-opt="-L/src/openssl/build/lib -static" \
    --with-cc-opt="-I/src/openssl/build/include" \
#    --with-mail \
#    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_quic_module \
    --with-stream_realip_module \
    --with-stream_ssl_preread_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v2_hpack_enc \
    --with-http_v3_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/ngx_security_headers && \
#    --add-module=/src/njs/nginx \
#    --add-module=/src/nginx-upstream-fair \
#    --add-module=/src/testcookie-nginx-module \
#    --add-module=/src/ngx_http_js_challenge_module \
# Build & Install
    cd /src/nginx && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/nginx/sbin/nginx

FROM python:3.11.3-alpine3.17
COPY --from=build /usr/local/nginx /usr/local/nginx
RUN apk add --no-cache ca-certificates tzdata libcap && \
    setcap cap_net_bind_service=ep /usr/local/nginx/sbin/nginx && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
