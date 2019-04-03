FROM centos:centos7.6.1810

ENV GOSU_VERSION 1.10
ENV GOSU_ARCH amd64
ENV GOSU_URL https://github.com/tianon/gosu/releases/download
ENV GOSU_APP ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}
ENV GOSU_ASC ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}.asc
ENV DB4_VERSION 4.8.30.NC
ENV DB4_HASH 12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef
ENV DB4_URL http://download.oracle.com/berkeley-db/db-${DB4_VERSION}.tar.gz
ENV BITCOIN_VERSION=0.17.1
ENV CORE_URL https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}
ENV PATH $PATH:/opt/bitcoin-${BITCOIN_VERSION}/bin

RUN set -x \
    && yum install -y epel-release \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN set -x \
    && yum install -y \
        gcc \
        gcc-c++ \
        make \
        curl-devel \
        libevent-devel \
        tcl-devel \
        tk-devel \
        zlib-devel \
        bzip2-devel \
        openssl-devel \
        ncurses-devel \
        readline-devel \
        gdbm-devel \
        file \
        libpcap-devel \
        xz-devel \
        expat-devel \
        snappy-devel \
        libevent-devel \
        libdb4-devel \
        libdb4-cxx-devel \
        zeromq-devel \
        gmp-devel \
        mpfr-devel \
        libmpc-devel \
        which \
        autoconf \
        automake \
        libtool \
        boost-devel \
        iproute \
        jq \
        python36 \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN set -x \
    && adduser -m -s /sbin/nologin bitcoin \
    && chown bitcoin:bitcoin /home/bitcoin \
    && curl -o /usr/local/bin/gosu -SL ${GOSU_APP} \
    && curl -o /usr/local/bin/gosu.asc -SL ${GOSU_ASC} \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
        B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -x \
    && cd /usr/src \
    && curl -L ${DB4_URL} -o db-${DB4_VERSION} \
    && echo "${DB4_HASH} db-${DB4_VERSION}" | sha256sum -c || exit 1 \
    && tar zxvf db-${DB4_VERSION} \
    && cd db-${DB4_VERSION}/build_unix \
    && ../dist/configure --prefix=/usr --enable-cxx \
        --disable-shared --with-pic \
    && make -j$(nproc) \
    && make install \
    && make clean \
    && cd /usr/src \
    && rm -rf /usr/src/db-${DB4_VERSION}

RUN set -x \
    && curl -SL https://bitcoin.org/laanwj-releases.asc | gpg --import \
    && curl -SLO ${CORE_URL}/SHA256SUMS.asc \
    && curl -SLO ${CORE_URL}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
    && gpg --verify SHA256SUMS.asc \
    && grep " bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz\$" SHA256SUMS.asc | sha256sum -c - \
    && tar -xzf *.tar.gz -C /opt \
    && rm -f *.tar.gz *.asc

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bitcoind"]
