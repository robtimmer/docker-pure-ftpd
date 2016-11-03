FROM alpine
MAINTAINER rob@robtimmer.com

# Arguments
ARG PUREFTPD_VERSION=1.0.43
ARG URL=http://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-$PUREFTPD_VERSION.tar.gz

# Environment variables
ENV PUBLIC_HOST         localhost
ENV MIN_PASV_PORT       30000
ENV MAX_PASV_PORT       30009
ENV UID                 1000
ENV GID                 1000

# Install Pure-FTPd
RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                build-base \
                                curl \
                                tar && \
    cd /tmp && \
    curl -sSL $URL | tar xz --strip 1 && \

    ./configure --prefix=/usr \
                --sysconfdir=/etc/pureftpd \
                --without-humor \
                --with-minimal \
                --with-throttling \
                --with-puredb \
                --with-rfc2640 \
                --with-peruserlimits \
                --with-ratios \
                --with-welcomemsg && \
    make install-strip && \
    cd .. && \
    rm -rf /tmp/* && \
    apk del .build-deps && \
    mkdir /etc/pureftpd

# Add entrypoint script
COPY entrypoint.sh /usr/bin/entrypoint.sh

# Volumes
VOLUME /home/ftpuser /etc/pureftpd

# Exposed ports
EXPOSE 21 $MIN_PASV_PORT-$MAX_PASV_PORT

# Start Pure-FTPd with parameters
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD /usr/sbin/pure-ftpd \
                        -P $PUBLIC_HOST \
                        -p $MIN_PASV_PORT:$MAX_PASV_PORT \
                        -l puredb:/etc/pureftpd/pureftpd.pdb \
                        -E \
                        -j \
                        -R
