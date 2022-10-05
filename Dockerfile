FROM debian:bullseye-20221004-slim

ARG BUILD=${BUILD}
ARG PAGESPEED_INCUBATOR_VERSION=1.14.36.1
    
# Copy Openresty
COPY openresty /src
    
# Requirements
ENV DEBIAN_FRONTEND=noninteractive
RUN rm -rf /etc/apt/sources.list && \
    echo "fs.file-max = 65535" > /etc/sysctl.conf && \
    echo "deb https://debian.inf.tu-dresden.de/debian bullseye main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://debian.inf.tu-dresden.de/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://debian.inf.tu-dresden.de/debian bullseye-proposed-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://debian.inf.tu-dresden.de/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://debian.inf.tu-dresden.de/debian bullseye-backports-sloppy main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    apt update -t bullseye-backports -y && \
    apt upgrade -t bullseye-backports -y --allow-downgrades && \
    apt dist-upgrade -t bullseye-backports -y --allow-downgrades && \
    apt autoremove -t bullseye-backports --purge -y && \
    apt autoclean -t bullseye-backports -y && \
    apt clean -t bullseye-backports -y && \
    apt -o DPkg::Options::="--force-confnew" -y install -t bullseye-backports -y curl gnupg ca-certificates apt-utils && \
    curl -Ls https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /usr/share/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x bullseye main" >> /etc/apt/sources.list && \
    apt update -t bullseye-backports -y && \
    apt upgrade -t bullseye-backports -y --allow-downgrades && \
    apt dist-upgrade -t bullseye-backports -y --allow-downgrades && \
    apt autoremove -t bullseye-backports --purge -y && \
    apt autoclean -t bullseye-backports -y && \
    apt clean -t bullseye-backports -y && \
    apt -o DPkg::Options::="--force-confnew" -y install -t bullseye-backports -y \
    mercurial dos2unix patch autoconf automake golang coreutils build-essential gnupg passwd \
    libpcre3 libpcre3-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev uuid-dev zlib1g-dev libgd-dev libgd3 libatomic-ops-dev libgeoip-dev libgeoip1 \
    libmaxminddb-dev libmaxminddb0 libmodsecurity3 libmodsecurity-dev libperl-dev libtool sysvinit-utils lua5.1 liblua5.1-dev lua-any lua-sec luarocks perl \
    libimage-imlib2-perl imagemagick libgd-dev libiconv-hook-dev libiconv-hook1 libzstd-dev \
    python3 python-is-python3 python3-pip nodejs sqlite3 logrotate dnsutils redis-tools redis-server tar git jq curl wget zip unzip figlet nano apache2-utils && \
    apt autoremove --purge -y && \
    apt autoclean -y && \
    apt clean -y && \
    curl -L https://yarnpkg.com/install.sh | bash && \
    pip install certbot && \
    useradd nginx && \

# Nginx
#    hg clone https://hg.nginx.org/nginx-quic -r "quic" /src && \
#    cd /src && \
#    hg pull && \
#    hg update quic && \

# Patches
#    cd /src && \
#    curl -L https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.17.7%2B.patch -o tcp-tls.patch && \
#    patch -p1 <tcp-tls.patch && \
#    rm -rf tcp-tls.patch && \
#    curl -L https://github.com/angristan/nginx-autoinstall/raw/master/patches/nginx_hpack_push_with_http3.patch -o nginx_http2_hpack.patch && \
#    patch -p1 <nginx_http2_hpack.patch && \
#    rm -rf nginx_http2_hpack.patch && \

# Openssl
    cd /src && \
    git clone --recursive https://github.com/quictls/openssl /src/openssl && \
    cd /src/openssl && \
    /src/openssl/Configure && \
    make -j "$(nproc)" && \

# Pagespeed
    cd /src && \
    git clone https://github.com/apache/incubator-pagespeed-ngx /src/incubator-pagespeed-ngx && \
    cd /src/incubator-pagespeed-ngx && \
    curl -L https://dist.apache.org/repos/dist/release/incubator/pagespeed/${PAGESPEED_INCUBATOR_VERSION}/x64/psol-${PAGESPEED_INCUBATOR_VERSION}-apache-incubating-x64.tar.gz | tar zx && \

# njs
    cd /src && \
    hg clone http://hg.nginx.org/njs /src/njs && \

# Brotli
    cd /src && \
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \

# zstd-nginx-module
    cd /src && \
    git clone --recursive https://github.com/tokers/zstd-nginx-module /src/zstd-nginx-module && \
    
# GeoIP
    cd /src && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module /src/ngx_http_geoip2_module && \
    
# ngx_security_headers
    cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_security_headers /src/ngx_security_headers && \

# Cache Purge
    cd /src && \
    git clone --recursive https://github.com/nginx-modules/ngx_cache_purge /src/ngx_cache_purge && \
    
# Nginx Substitutions Filter
    cd /src && \
    git clone --recursive https://github.com/yaoweibin/ngx_http_substitutions_filter_module /src/ngx_http_substitutions_filter_module && \

# fancyindex
    cd /src && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \
    
    cd /src && \
    git clone --recursive https://github.com/SanCraftDev/Nginx-Fancyindex-Theme && \
    mv /src/Nginx-Fancyindex-Theme/Nginx-Fancyindex-Theme-dark /Nginx-Fancyindex-Theme-dark && \

# webdav
    cd /src && \
    git clone --recursive https://github.com/arut/nginx-dav-ext-module /src/nginx-dav-ext-module && \

# vts
    cd /src && \
    git clone --recursive https://github.com/vozlt/nginx-module-vts /src/nginx-module-vts && \

# flv
    cd /src && \
    git clone --recursive https://github.com/winshining/nginx-http-flv-module /src/nginx-http-flv-module && \

# testcookie
    cd /src && \
    git clone --recursive https://github.com/kyprizel/testcookie-nginx-module /src/testcookie-nginx-module && \

# modsec
    cd /src && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx /src/ModSecurity-nginx && \

# nginx_accept_language_module
    cd /src && \
    git clone --recursive https://github.com/dvershinin/nginx_accept_language_module /src/nginx_accept_language_module && \
    
# nginx-upload-module
    cd /src && \
    git clone --recursive https://github.com/fdintino/nginx-upload-module /src/nginx-upload-module && \
    
# f4fhds
    cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/f4fhds /src/f4fhds && \
    
# nginx-upstream-fair
    cd /src && \
    git clone --recursive https://github.com/itoffshore/nginx-upstream-fair /src/nginx-upstream-fair && \
    
# mod_zip
    cd /src && \
    git clone --recursive https://github.com/evanmiller/mod_zip /src/mod_zip && \
    
# nginx-statsd
    cd /src && \
    git clone --recursive https://github.com/getsentry/nginx-statsd /src/nginx-statsd && \
    
# nginx-module-sts
    cd /src && \
    git clone --recursive https://github.com/vozlt/nginx-module-sts /src/nginx-module-sts && \
    
# nginx-fips-check-module
    cd /src && \
    git clone --recursive https://github.com/ogarrett/nginx-fips-check-module /src/nginx-fips-check-module && \
    
# nginx-sticky-module-ng
    cd /src && \
    git clone --recursive https://github.com/dvershinin/nginx-sticky-module-ng /src/nginx-sticky-module-ng && \
    
# ngx_http_google_filter_module
    cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_http_google_filter_module /src/ngx_http_google_filter_module && \
    
# nginx-ts-module 
    cd /src && \
    git clone --recursive https://github.com/arut/nginx-ts-module /src/nginx-ts-module && \
    
# ngx_http_js_challenge_module
    cd /src && \
    git clone --recursive https://github.com/dvershinin/ngx_http_js_challenge_module /src/ngx_http_js_challenge_module && \
    
# ngx_http_captcha_module
    cd /src && \
    git clone --recursive https://github.com/dvershinin/ngx_http_captcha_module /src/ngx_http_captcha_module && \
    
# ngx_cookie_limit_req_module
#    cd /src && \
#    git clone --recursive https://github.com/limithit/ngx_cookie_limit_req_module /src/ngx_cookie_limit_req_module && \
    
# modjpeg-nginx
#    cd /src && \
#    git clone --recursive https://github.com/ioppermann/modjpeg-nginx /src/modjpeg-nginx && \

# Configure
    cd /src && \
    /src/configure \
    --with-debug \
    --build=${BUILD} \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/lib/nginx/modules \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --user=nginx \
    --group=nginx \
    --with-cc-opt=-Wno-deprecated-declarations \
    --with-cc-opt=-Wno-ignored-qualifiers \
    --with-ipv6 \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-pcre-jit \
    --with-libatomic \
    --with-cpp_test_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_quic_module \
    --with-stream_geoip_module \
    --with-stream_realip_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_ssl_module \
    --with-http_v2_hpack_enc \
    --with-http_mp4_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_perl_module \
    --with-http_xslt_module \
    --with-http_geoip_module \
    --with-http_slice_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_addition_module \
    --with-http_degradation_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_secure_link_module \
    --with-http_image_filter_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --add-module=/src/f4fhds \
    --add-module=/src/mod_zip \
    --add-module=/src/njs/nginx \
    --add-module=/src/ngx_brotli \
    --add-module=/src/nginx-statsd \
#    --add-module=/src/modjpeg-nginx \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/ngx_cache_purge \
    --add-module=/src/nginx-ts-module \
    --add-module=/src/nginx-module-vts \
    --add-module=/src/nginx-module-sts \
    --add-module=/src/ModSecurity-nginx \
    --add-module=/src/zstd-nginx-module \
    --add-module=/src/nginx-upstream-fair \
    --add-module=/src/nginx-upload-module \
    --add-module=/src/ngx_security_headers \
    --add-module=/src/nginx-dav-ext-module \
    --add-module=/src/nginx-http-flv-module \
    --add-module=/src/ngx_http_geoip2_module \
    --add-module=/src/nginx-sticky-module-ng \
    --add-module=/src/ngx_http_captcha_module \
    --add-module=/src/nginx-fips-check-module \
    --add-module=/src/testcookie-nginx-module \
    --add-module=/src/incubator-pagespeed-ngx \
#    --add-module=/src/ngx_cookie_limit_req_module \
    --add-module=/src/nginx_accept_language_module \
    --add-module=/src/ngx_http_js_challenge_module \
    --add-module=/src/ngx_http_google_filter_module \
    --add-module=/src/ngx_http_substitutions_filter_module \
    --with-openssl="/src/openssl" \
    --with-cc-opt="-I/src/openssl/build/include" \
    --with-ld-opt="-L/src/openssl/build/lib" && \
    
# Build & Install
    cd /src && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    
    cd /src && \
    strip -s /usr/sbin/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/log/nginx && \
    
    cd /src && \
    mkdir /etc/nginx/modsec && \
    curl -L https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended -o /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf && \
    
    cd /src && \
    curl -L https://ssl-config.mozilla.org/ffdhe2048.txt -o /etc/ssl/dhparam && \

# Clean
    cd / && \
    rm -rf /src && \

# Copy version into env
    cd / && \
    nginx -v 2> v && \
    sed -i "s/nginx version: //g" v

LABEL org.opencontainers.image.source="https://github.com/SanCraftDev/openresty-nginx-quic"
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
