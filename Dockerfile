FROM debian:bullseye-slim

ARG BUILD=${BUILD}
ARG PAGESPEED_INCUBATOR_VERSION=1.14.36.1
    
# Requirements
ENV DEBIAN_FRONTEND=noninteractive
RUN rm /etc/apt/sources.list && \
    echo "fs.file-max = 65535" > /etc/sysctl.conf && \
    echo "deb http://deb.debian.org/debian bullseye main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
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
    mercurial dos2unix patch autoconf automake golang coreutils build-essential gnupg passwd \
    libpcre3 libpcre3-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev uuid-dev zlib1g-dev libgd-dev libgd3 libatomic-ops-dev libgeoip-dev libgeoip1 \
    libmaxminddb-dev libmaxminddb0 libmodsecurity3 libmodsecurity-dev libperl-dev libtool sysvinit-utils lua5.1 liblua5.1-dev lua-any lua-sec luarocks perl \
    python3 python-is-python3 python3-pip nodejs sqlite3 logrotate dnsutils redis-tools redis-server tar git jq curl wget zip unzip figlet nano apache2-utils && \
    apt autoremove --purge -y && \
    apt autoclean -y && \
    apt clean -y && \
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash && \
    pip install certbot && \
    useradd nginx
    
# Openresty Install
RUN git clone --recursive https://github.com/SanCraftDev/openresty-quic /src && \
    
    cd /src && \
    make -j "$(nproc)" && \
    
    cd /src && \
    rm openresty-*.tar.gz && \
    mv openresty-* .. && \
    cd / && \
    rm -rf /src && \
    mv openresty-* /src

# Openssl
RUN cd /src && \
    git clone --recursive https://github.com/quictls/openssl /src/openssl && \
    cd /src/openssl && \
    /src/openssl/Configure && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install

# Pagespeed
RUN cd /src && \
    git clone https://github.com/apache/incubator-pagespeed-ngx /src/incubator-pagespeed-ngx && \
    cd /src/incubator-pagespeed-ngx && \
    curl -L https://dist.apache.org/repos/dist/release/incubator/pagespeed/${PAGESPEED_INCUBATOR_VERSION}/x64/psol-${PAGESPEED_INCUBATOR_VERSION}-apache-incubating-x64.tar.gz | tar zx

# Brotli
RUN cd /src && \
    git clone --recursive https://github.com/google/ngx_brotli /src/ngx_brotli
    
# GeoIP
RUN cd /src && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module /src/ngx_http_geoip2_module
    
# ngx_security_headers
RUN cd /src && \
    git clone --recursive https://github.com/GetPageSpeed/ngx_security_headers /src/ngx_security_headers

# Cache Purge
RUN cd /src && \
    git clone --recursive https://github.com/FRiCKLE/ngx_cache_purge /src/ngx_cache_purge
    
# Nginx Substitutions Filter
RUN cd /src && \
    git clone --recursive https://github.com/yaoweibin/ngx_http_substitutions_filter_module /src/ngx_http_substitutions_filter_module

# fancyindex
RUN cd /src && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex /src/ngx-fancyindex
    
RUN cd /src && \
    git clone --recursive https://github.com/SanCraftDev/Nginx-Fancyindex-Theme && \
    mv /src/Nginx-Fancyindex-Theme/Nginx-Fancyindex-Theme-dark /Nginx-Fancyindex-Theme-dark

# webdav
RUN cd /src && \
    git clone --recursive https://github.com/arut/nginx-dav-ext-module /src/nginx-dav-ext-module

# vts
RUN cd /src && \
    git clone --recursive https://github.com/vozlt/nginx-module-vts /src/nginx-module-vts

# rtmp
RUN cd /src && \
    git clone --recursive https://github.com/arut/nginx-rtmp-module /src/nginx-rtmp-module

# testcookie
RUN cd /src && \
    git clone --recursive https://github.com/kyprizel/testcookie-nginx-module /src/testcookie-nginx-module

# modsec
RUN cd /src && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx /src/ModSecurity-nginx

# Configure
RUN cd /src && \
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
    --add-module=/src/ngx_security_headers \
    --add-module=/src/nginx-dav-ext-module \
    --add-module=/src/ngx_http_geoip2_module \
    --add-module=/src/testcookie-nginx-module \
    --add-module=/src/incubator-pagespeed-ngx \
    --add-module=/src/ngx_http_substitutions_filter_module \
    --with-openssl="/src/openssl" \
    --with-cc-opt="-I/src/openssl/build/include" \
    --with-ld-opt="-L/src/openssl/build/lib"
    
# Build & Install
RUN cd /src && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install
    
RUN cd /src && \
    strip -s /usr/sbin/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/log/nginx
    
RUN cd /src && \
    mkdir /etc/nginx/modsec && \
    curl -L https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended -o /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    
RUN cd /src && \
    curl -L https://ssl-config.mozilla.org/ffdhe2048.txt -o /dhparam

# Clean
RUN rm -rf /src

ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
