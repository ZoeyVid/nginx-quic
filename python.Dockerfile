# syntax=docker/dockerfile:labs
FROM python:3.12.4-alpine3.20
COPY --from=zoeyvid/nginx-quic:latest /usr/local/nginx                               /usr/local/nginx
#COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/perl5                           /usr/local/lib/perl5 # perl in apk add needed
#COPY --from=zoeyvid/nginx-quic:latest /usr/lib/perl5/core_perl/perllocal.pod         /usr/lib/perl5/core_perl/perllocal.pod # perl in apk add needed
COPY --from=zoeyvid/nginx-quic:latest /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
