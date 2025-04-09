# syntax=docker/dockerfile:labs
FROM python:3.13.3-alpine3.21 AS certbot
COPY requirements.txt /tmp/requirements.txt
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates build-base libffi-dev && \
    python3 -m venv /usr/local && \
    pip install --no-cache-dir -r /tmp/requirements.txt

FROM python:3.13.3-alpine3.21
ENV PYTHONUNBUFFERED=1
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY --from=zoeyvid/nginx-quic:latest /usr/local/nginx                                /usr/local/nginx
COPY --from=zoeyvid/nginx-quic:latest /etc/ssl/openssl.cnf                            /etc/ssl/openssl.cnf
COPY --from=zoeyvid/nginx-quic:latest /usr/lib/ossl-modules/oqsprovider.so            /usr/lib/ossl-modules/oqsprovider.so
COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/libmodsecurity.so.3              /usr/local/lib/libmodsecurity.so.3
COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/libopentelemetry_proto.so        /usr/local/lib/libopentelemetry_proto.so
COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/libosrc_shmem_ipc.so             /usr/local/lib/libosrc_shmem_ipc.so
COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/libosrc_compression_utils.so     /usr/local/lib/libosrc_compression_utils.so
COPY --from=zoeyvid/nginx-quic:latest /usr/local/lib/libosrc_nginx_attachment_util.so /usr/local/lib/libosrc_nginx_attachment_util.so
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs libprotobuf openssl && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
COPY --from=certbot /usr/local /usr/local

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
