# nginx-quic
Docker image for nginx with HTTP/3-module - used as base image for NPMplus, it also contains libmodsec, some patches and some modules (including lua), you can find the all links in the Dockerfile. The python-version/python-latest build also contains python and certbot.

If you use the tar files, please move the files in the lib folder to the `/usr/local/lib` folder.
See the last build step of the Dockerfile for dependencies <br>
