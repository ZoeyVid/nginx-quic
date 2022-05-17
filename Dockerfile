FROM debian:bullseye-slim

ARG BUILD=${BUILD}

ENV DEBIAN_FRONTEND=noninteractive \
# Versions
    LUAROCK_VERSION=luarocks_3.8.0+dfsg1-1_all.deb \
    OPENRESTY_VERSION=openresty-1.21.4.1rc3 \
    PAGESPEED_INCUBATOR_VERSION=1.14.36.1 \
    NGINX_VERSION=nginx-1.21.4
    
# Requirements
RUN rm /etc/apt/sources.list && \
    echo "fs.file-max = 65535" > /etc/sysctl.conf && \
    echo "deb http://deb.debian.org/debian bullseye main contrib" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bullseye-updates main contrib" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main contrib" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bullseye-security main contrib" >> /etc/apt/sources.list && \
    apt update -y && \
    apt upgrade -y --allow-downgrades && \
    apt dist-upgrade -y --allow-downgrades && \
    apt autoremove --purge -y && \
    apt autoclean -y && \
    apt clean -y && \
    apt -o DPkg::Options::="--force-confnew" -y install curl gnupg ca-certificates apt-utils && \
    curl -Ls https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /usr/share/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x bullseye main" >> /etc/apt/sources.list && \
    apt update -y && \
    apt upgrade -y --allow-downgrades && \
    apt dist-upgrade -y --allow-downgrades && \
    apt autoremove --purge -y && \
    apt autoclean -y && \
    apt clean -y && \
    apt -o DPkg::Options::="--force-confnew" -y install -y \
    mercurial patch autoconf automake golang coreutils build-essential gnupg passwd \
    libpcre3 libpcre3-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev uuid-dev zlib1g-dev libgd-dev libgd3 libatomic-ops-dev libgeoip-dev libgeoip1 \
    libmaxminddb-dev libmaxminddb0 libmodsecurity3 libmodsecurity-dev libperl-dev libtool sysvinit-utils lua5.1 liblua5.1-dev lua-any lua-sec luarocks \
    python3 python-is-python3 python3-pip certbot nodejs sqlite3 logrotate knot-dnsutils redis-tools redis-server perl tar git jq curl wget zip unzip && \
    apt autoremove --purge -y && \
    apt autoclean -y && \
    apt clean -y && \
    npm i -g npm yarn && \
    useradd nginx && \

# Openresty Install
    curl -L https://openresty.org/download/${OPENRESTY_VERSION}.tar.gz | tar zx && \
    mv ${OPENRESTY_VERSION} /src && \

# Nginx Install
    rm -rf /src/bundle/${NGINX_VERSION} && \
    hg clone https://hg.nginx.org/nginx-quic -r "quic" /src/bundle/${NGINX_VERSION} && \
    hg clone http://hg.nginx.org/njs /src/bundle/njs && \
    cd /src/bundle/${NGINX_VERSION} && \
    hg pull && \
    hg update quic && \

# luarocks install
    curl -L https://ftp.debian.org/debian/pool/main/l/luarocks/${LUAROCK_VERSION} -o /src/luarocks.deb && \
    dpkg -i /src/luarocks.deb && \

# Pagespeed
    cd /src && \
    git clone https://github.com/apache/incubator-pagespeed-ngx /src/incubator-pagespeed-ngx && \
    cd /src/incubator-pagespeed-ngx && \
    curl -L https://dist.apache.org/repos/dist/release/incubator/pagespeed/${PAGESPEED_INCUBATOR_VERSION}/x64/psol-${PAGESPEED_INCUBATOR_VERSION}-apache-incubating-x64.tar.gz | tar zx && \

# Brotli
    cd /src && \
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli && \
    
# GeoIP
    cd /src && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module /src/ngx_http_geoip2_module && \

# Cache Purge
    cd /src && \
    git clone --recursive https://github.com/FRiCKLE/ngx_cache_purge /src/ngx_cache_purge && \
    
# Nginx Substitutions Filter
    cd /src && \
    git clone --recursive https://github.com/yaoweibin/ngx_http_substitutions_filter_module /src/ngx_http_substitutions_filter_module && \

# fancyindex
    cd /src && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex && \

# webdav
    cd /src && \
    git clone --recursive https://github.com/arut/nginx-dav-ext-module /src/nginx-dav-ext-module && \

# vts
    cd /src && \
    git clone --recursive https://github.com/vozlt/nginx-module-vts /src/nginx-module-vts && \

# rtmp
    cd /src && \
    git clone --recursive https://github.com/arut/nginx-rtmp-module /src/nginx-rtmp-module && \

# testcookie
    cd /src && \
    git clone --recursive https://github.com/kyprizel/testcookie-nginx-module /src/testcookie-nginx-module && \

# modsec
    cd /src && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx /src/ModSecurity-nginx && \

# openresty-nginx-quic patch
    cd /src && \
    curl -L https://raw.githubusercontent.com/SanCraftDev/nginx-quic/develop/configure.patch -o configure.patch && \
    patch < configure.patch && \

# Cloudflare's TLS Dynamic Record Resizing patch & full HPACK encoding patch
    cd /src/bundle/${NGINX_VERSION} && \
    curl -L https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.17.7%2B.patch -o tcp-tls.patch && \
    patch -p1 <tcp-tls.patch && \
    curl -L https://github.com/angristan/nginx-autoinstall/raw/master/patches/nginx_hpack_push_with_http3.patch -o nginx_http2_hpack.patch && \
    patch -p1 <nginx_http2_hpack.patch && \
    
# Openssl
    cd /src && \
    git clone --recursive https://github.com/quictls/openssl /src/openssl && \
    cd /src/openssl && \
    /src/openssl/Configure && \
    gmake -j "$(nproc)" && \

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
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-module=/src/ngx_cache_purge \
    --add-module=/src/nginx-module-vts \
    --add-module=/src/ModSecurity-nginx \
    --add-module=/src/nginx-rtmp-module \
    --add-module=/src/nginx-dav-ext-module \
    --add-module=/src/ngx_http_geoip2_module \
    --add-module=/src/testcookie-nginx-module \
    --add-module=/src/incubator-pagespeed-ngx \
    --add-module=/src/ngx_http_substitutions_filter_module \
    --with-openssl="/src/openssl" \
    --with-cc-opt="-I/src/openssl/build/include" \
    --with-ld-opt="-L/src/openssl/build/lib" && \
    
# Build & Install
    cd /src && \
    gmake -j "$(nproc)" && \
    gmake -j "$(nproc)" install && \
    
    cd /src && \
    strip -s /usr/sbin/nginx && \
    
    cd /src && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/log/nginx && \
    
    cd /src && \
    mkdir /etc/nginx/modsec && \
    curl -L https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended -o /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf && \
    
    cd /src && \
    luarocks install lua-cjson && \
    luarocks install lua-resty-openidc && \

# Clean
    mv /src/build/luajit-root /luajit-root && \
    rm -rf /src && \
    mkdir -p /src/build && \
    mv /luajit-root /src/build/luajit-root

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
