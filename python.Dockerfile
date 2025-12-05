# syntax=docker/dockerfile:labs
ARG IMAGE
FROM ${IMAGE:-ghcr.io/zoeyvid/nginx-quic:latest} AS nginx

FROM python:3.14.1-alpine3.22 AS certbot
COPY requirements.txt /tmp/requirements.txt
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates build-base libffi-dev && \
    python3 -m venv /usr/local && \
    pip install --no-cache-dir -r /tmp/requirements.txt

FROM python:3.14.1-alpine3.23
#ENV PYTHONUNBUFFERED=1
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY --from=nginx /usr/local/nginx                                /usr/local/nginx
COPY --from=nginx /usr/local/lib/libmodsecurity.so.3              /usr/local/lib/libmodsecurity.so.3
COPY --from=nginx /usr/local/lib/libopentelemetry_proto.so        /usr/local/lib/libopentelemetry_proto.so
COPY --from=nginx /usr/local/lib/libosrc_shmem_ipc.so             /usr/local/lib/libosrc_shmem_ipc.so
COPY --from=nginx /usr/local/lib/libosrc_compression_utils.so     /usr/local/lib/libosrc_compression_utils.so
COPY --from=nginx /usr/local/lib/libosrc_nginx_attachment_util.so /usr/local/lib/libosrc_nginx_attachment_util.so
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini lua-resty-core lua-resty-lrucache luajit pcre2 zlib brotli zstd openssl && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
COPY --from=certbot /usr/local /usr/local

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
EXPOSE 80/tcp
EXPOSE 81/tcp
EXPOSE 443/tcp
EXPOSE 443/udp
