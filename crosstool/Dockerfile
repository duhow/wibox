FROM ubuntu:18.04 AS build

ARG CROSSTOOL_VERSION=1.24.0 \
    CROSS_BUILD=arm-goke-linux-uclibcgnueabi

COPY src /ct-ng-${CROSS_BUILD}/src/

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
    usermod -aG sudo -d $PWD build && \
    chown -R build:build /ct-ng-${CROSS_BUILD} && \
    chmod a+rw /ct-ng-${CROSS_BUILD}

COPY .config /ct-ng-${CROSS_BUILD}/

WORKDIR /ct-ng-${CROSS_BUILD}
USER build
RUN ct-ng build

# ------

FROM ubuntu:18.04

ARG CROSS_BUILD=arm-goke-linux-uclibcgnueabi

RUN apt update && \
    apt install -y sudo tar xz-utils unzip bzip2 build-essential bison \
      flex texinfo help2man file gawk libtool libtool-bin libncurses-dev wget curl

COPY --from=build /ct-ng-${CROSS_BUILD}/x-tools/${CROSS_BUILD} /${CROSS_BUILD}/

ENV CROSS_COMPILE=${CROSS_BUILD}-
ENV PATH=/${CROSS_BUILD}/bin:${PATH}
