# AUTOMATICALLY GENERATED
# DO NOT EDIT THIS FILE DIRECTLY, USE /Dockerfile.tmpl.php

# https://hub.docker.com/_/debian
FROM debian:buster-slim
LABEL Luc Appelman "lucapppelman@gmail.com"

# Build and install OpenDKIM
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
                inetutils-syslogd \
                ca-certificates \
    && update-ca-certificates \
    # Install OpenDKIM dependencies
    && apt-get install -y --no-install-recommends --no-install-suggests \
                #newer version does not work with opendkim yet
                #libssl1.1 \
                libmilter1.0.1 \
                libbsd0 \
    # Install tools for building
    && toolDeps="curl make gcc g++ libc-dev" \
    && apt-get install -y --no-install-recommends --no-install-suggests $toolDeps \
    # Install OpenDKIM build dependencies
    && buildDeps=" \
            libssl-dev \
            libmilter-dev \
            libbsd-dev" \
    && apt-get install -y --no-install-recommends --no-install-suggests $buildDeps \
    # Download libssl1.0.2
    && curl -fL -o /tmp/libssl1.0.2_amd64.deb http://security.debian.org/debian-security/pool/updates/main/o/openssl1.0/libssl1.0.2_1.0.2u-1~deb9u2_amd64.deb \
    && apt install /tmp/libssl1.0.2_amd64.deb \
    # Download and prepare OpenDKIM sources
    && curl -fL -o /tmp/opendkim.tar.gz https://downloads.sourceforge.net/project/opendkim/opendkim-2.10.3.tar.gz \
    && (echo "97923e533d072c07ae4d16a46cbed95ee799aa50f19468d8bc6d1dc534025a8616c3b4b68b5842bc899b509349a2c9a67312d574a726b048c0ea46dd4fcc45d8  /tmp/opendkim.tar.gz" | sha512sum -c -) \
    && tar -xzf /tmp/opendkim.tar.gz -C /tmp/ \
    && cd /tmp/opendkim-* \
    # Build OpenDKIM from sources
    && ./configure \
            --prefix=/usr \
            --sysconfdir=/etc/opendkim \
            # No documentation included to keep image size smaller
            --docdir=/tmp/opendkim/doc \
            --htmldir=/tmp/opendkim/html \
            --infodir=/tmp/opendkim/info \
            --mandir=/tmp/opendkim/man \
    && make \
    # Create OpenDKIM user and group
    && addgroup --system --gid 91 opendkim \
    && adduser --system --uid 90 --disabled-password --shell /sbin/nologin \
                --no-create-home --home /run/opendkim \
                --ingroup opendkim --gecos opendkim \
                opendkim \
    && adduser opendkim mail \
    # Install OpenDKIM
    && make install \
    # Prepare run directory
    && install -d -o opendkim -g opendkim /run/opendkim/ \
    # Preserve licenses
    && install -d /usr/share/licenses/opendkim/ \
    && mv /tmp/opendkim/doc/LICENSE* \
        /usr/share/licenses/opendkim/ \
    # Prepare configuration directories
    && install -d /etc/opendkim/conf.d/ \
    # Cleanup unnecessary stuff
    && apt-get purge -y --auto-remove \
                -o APT::AutoRemove::RecommendsImportant=false \
                $toolDeps $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
            /etc/*/inetutils-syslogd \
            /tmp/*

# Install s6-overlay
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests curl \
    && curl -fL -o /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz \
    && tar -xzf /tmp/s6-overlay.tar.gz -C / \
    # Cleanup unnecessary stuff
    && apt-get purge -y --auto-remove \
                -o APT::AutoRemove::RecommendsImportant=false \
                curl \
    && rm -rf /var/lib/apt/lists/* \
            /tmp/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1

COPY rootfs /

RUN chmod +x /etc/services.d/*/run \
            /etc/cont-init.d/*

EXPOSE 8891

WORKDIR /etc/opendkim

VOLUME /etc/ssl/dkim

STOPSIGNAL SIGTERM

ENTRYPOINT ["/init"]

CMD ["opendkim", "-f"]