FROM ubuntu
RUN apt-get update && \
    apt-get install -y \
        inetutils-ping iproute2 iptables git curl gcc
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN gcc -o tproxy_captive_portal /usr/src/app/tproxy_captive_portal.c