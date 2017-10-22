FROM xataz/alpine:3.6

LABEL Description="reverse with nginx based on alpine" \
      tags="latest mainline 1.13.6 1.13" \
      maintainer="xataz <https://github.com/xataz>" \
      build_ver="2017092202"

ARG NGINX_VER=1.13.6
ARG NGINX_GPG="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
               A09CD539B8BB8CBE96E82BDFABD4D3B3F5806B4D \
               4C2C85E705DC730833990C38A9376139A524C53E \
               65506C02EFC250F1B7A3D694ECF0E90B2C172083 \
               B0F4253373F8F6F510D42178520A9993A1C052F8 \
               7338973069ED3F443F4D37DFA64FD5B17ADB39A8"
ARG BUILD_CORES
ARG NGINX_CONF="--prefix=/nginx \
                --sbin-path=/usr/local/sbin/nginx \
                --http-log-path=/nginx/log/nginx_access.log \
                --error-log-path=/nginx/log/nginx_error.log \
                --pid-path=/nginx/run/nginx.pid \
                --lock-path=/nginx/run/nginx.lock \
                --user=reverse --group=reverse \
                --with-http_ssl_module \
                --with-http_v2_module \
                --with-http_gzip_static_module \
                --with-http_stub_status_module \
                --with-threads \
                --with-pcre-jit \
                --with-ipv6 \
                --without-http_ssi_module \
                --without-http_scgi_module \
                --without-http_uwsgi_module \
                --without-http_geo_module \
                --without-http_autoindex_module \
                --without-http_map_module \
                --without-http_split_clients_module \
                --without-http_memcached_module \
                --without-http_empty_gif_module \
                --add-module=/tmp/headers-more-nginx-module \
                --without-http_browser_module"

ENV UID=991 \
    GID=991 \
    EMAIL=admin@mydomain.local \
    SWARM=disable \
    TLS_VERSIONS="TLSv1.1 TLSv1.2" \
    CIPHER_SUITE="ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-ECDSA-CHACHA20-POLY1305-D:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"

RUN export BUILD_DEPS="build-base \
                    libressl-dev \
                    pcre-dev \
                    zlib-dev \
                    libc-dev \
                    wget \
                    gnupg \
                    go \
                    git" \
    && NB_CORES=${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} \
    && apk add -U ${BUILD_DEPS} \
                s6 \
                su-exec \
                ca-certificates \
                curl \
                jq \
                libressl \
                pcre \
                zlib \
                bash \
    && cd /tmp \
    && git clone https://github.com/openresty/headers-more-nginx-module --depth=1 \
    && wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz \
    && wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz.asc \
    && for server in ha.pool.sks-keyservers.net hkp://keyserver.ubuntu.com:80 hkp://p80.pool.sks-keyservers.net:80 pgp.mit.edu; \
	    do \
            echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
            gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys $NGINX_GPG && found=yes && break; \
        done \
    && gpg --batch --verify nginx-${NGINX_VER}.tar.gz.asc nginx-${NGINX_VER}.tar.gz \
    && tar xzf nginx-${NGINX_VER}.tar.gz \
    && cd /tmp/nginx-${NGINX_VER} \
    && ./configure ${NGINX_CONF} \            
    && make -j ${NB_CORES} \
    && make install \
    && mkdir -p /tmp/go/bin \
    && export GOPATH=/tmp/go \
    && export GOBIN=$GOPATH/bin \
    && git config --global http.https://gopkg.in.followRedirects true \
    && go get github.com/xenolf/lego \
    && mv /tmp/go/bin/lego /usr/local/bin/lego \
    && apk del ${BUILD_DEPS} \
    && rm -rf /tmp/* /var/cache/apk/*

COPY rootfs /
RUN chmod +x /usr/local/bin/startup /etc/s6.d/*/*

EXPOSE 8080 8443

ENTRYPOINT ["/usr/local/bin/startup"]
CMD ["/bin/s6-svscan", "/etc/s6.d"]
