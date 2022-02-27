FROM ubuntu:18.04

ARG CROSSTOOL_VERSION=1.24.0 \
    CROSS_BUILD=arm-goke-linux-uclibcgnueabi

RUN apt update && \
    apt install -y sudo tar xz-utils unzip bzip2 build-essential bison \
      flex texinfo help2man file gawk libtool libtool-bin libncurses-dev wget curl && \
    wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_VERSION}.tar.xz && \
    tar xvf crosstool-ng-${CROSSTOOL_VERSION}.tar.xz && \
    rm -f crosstool-ng-*.tar.* && \
    cd crosstool-ng-* && \
    ./configure && make && sudo make install && \
    mkdir -p /ct-ng-${CROSS_BUILD} && \
    cd /ct-ng-${CROSS_BUILD} && \
    ct-ng arm-unknown-linux-uclibcgnueabi && \
    useradd build && \
    usermod -d $PWD build && \
    sudo chmod a+rw .

COPY .config /ct-ng-${CROSS_BUILD}/
COPY src /ct-ng-${CROSS_BUILD}/src/

WORKDIR /ct-ng-${CROSS_BUILD}
USER build
RUN ct-ng build
