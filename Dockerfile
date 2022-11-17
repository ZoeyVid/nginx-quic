FROM alpine:20221110 as build

ARG BUILD=${BUILD}

# Requirements
RUN apk upgrade --no-cache && \ 
    apk add --no-cache ca-certificates wget git make perl gcc g++ linux-headers \
    pcre-dev zlib-dev libatomic_ops-dev && \
    mkdir /src && \

# Openssl
    cd /src && \
    git clone --recursive https://github.com/quictls/openssl /src/openssl && \
    cd /src/openssl && \
    /src/openssl/Configure && \
    make -j "$(nproc)" && \

# Nginx
    hg clone https://hg.nginx.org/nginx-quic -r "quic" /src/nginx && \
    cd /src/nginx && \
    wget https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.17.7%2B.patch -O tcp-tls.patch && \
    wget https://github.com/angristan/nginx-autoinstall/raw/master/patches/nginx_hpack_push_with_http3.patch -O nginx_http2_hpack.patch && \
    patch -p1 <tcp-tls.patch && \
    patch -p1 <nginx_http2_hpack.patch && \
    rm -rf *.patch && \

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

# fancyindex
    cd /src && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \
    
# ngx_security_headers
    cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_security_headers /src/ngx_security_headers && \

# Brotli
#    cd /src && \
#    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \

# Configure
    cd /src/nginx && \
    /src/nginx/configure \
    --build=${BUILD} \
    --with-ipv6 \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-pcre \
    --with-pcre-jit \
    --with-libatomic \
    --without-poll_module \
    --without-select_module \
    --with-openssl="/src/openssl" \
    --with-cc-opt="-I/src/openssl/build/include" \
    --with-ld-opt="-L/src/openssl/build/lib" \
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
    --with-http_auth_request_module \
#    --add-module=/src/njs/nginx \
#    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/ngx_security_headers && \
#    --add-module=/src/nginx-upstream-fair \
#    --add-module=/src/testcookie-nginx-module \
#    --add-module=/src/ngx_http_js_challenge_module \
    
# Build & Install
    cd /src/nginx && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/local/nginx/sbin/nginx

FROM alpine:20221110
COPY --from=build /usr/local/nginx /usr/local/nginx

RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates wget pcre-dev zlib-dev && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

LABEL org.opencontainers.image.source="https://github.com/SanCraftDev/nginx-quic"
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
