![](http://nginx.org/nginx.png)

# BETA VERSION ACTUALY !!!!!
[![Build Status](https://drone.xataz.net/api/badges/xataz/docker-reverse-nginx/status.svg)](https://drone.xataz.net/xataz/docker-reverse-nginx)
[![](https://images.microbadger.com/badges/image/xataz/reverse-nginx.svg)](https://microbadger.com/images/xataz/reverse-nginx "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/xataz/reverse-nginx.svg)](https://microbadger.com/images/xataz/reverse-nginx "Get your own version badge on microbadger.com")

> This image is build and push with [drone.io](https://github.com/drone/drone), a circle-ci like self-hosted.
> If you don't trust, you can build yourself.

## Tag available
* latest, 1.13.10, 1.13 [(Dockerfile)](https://github.com/xataz/docker-reverse-nginx/blob/master/Dockerfile)

**I've created new version rules, Before, I used nginx version, but now I will use [MAJOR-VERSION].[MINOR-VERSION].[BUG-FIXES].**
**I will use both notations**

## Features
* No ROOT process
* Automatic configuration generation
* Automatic certificate generation and renew with letsencrypt and without downtime (use lego)
* Latest nginx version
* ARG for custom build
* Latest openSSL version
* OCSP Support
* HSTS Support
* CT Support

## Description
What is [Nginx](http://nginx.org)?

nginx (engine x) is an HTTP and reverse proxy server, a mail proxy server, and a generic TCP proxy server, originally written by Igor Sysoev. For a long time, it has been running on many heavily loaded Russian sites including Yandex, Mail.Ru, VK, and Rambler. According to Netcraft, nginx served or proxied 24.29% busiest sites in December 2015. Here are some of the success stories: Netflix, Wordpress.com, FastMail.FM.

Reverse-nginx generate for you the configuration of reverse proxy. Like traefik, it is based on the labels of containers, but it isn't dynamicly.

## Build Image
### Build arguments
* NGINX_CONF : Nginx make configure options
* NGINX_VER : Nginx version
* ARG NGINX_GPG : GPG fingerprint (default : "B0F4253373F8F6F510D42178520A9993A1C052F8")
* ARG BUILD_CORES : Number of core use for make nginx (default : All cores)

### Simply build
```shell
docker build -t xataz/reverse-nginx github.com/xataz/dockerfiles.git#master:reverse-nginx
```
### Build other version
```shell
docker build -t xataz/reverse-nginx --build-arg NGINX_VER=1.9.5 github.com/xataz/dockerfiles.git#master:reverse-nginx
```

## Configuration
### Environments
* UID : Choose uid for launch nginx (default : 991)
* GID : Choose gid for launch nginx (default : 991) (Use local docker group id)
* EMAIL : Mail address for letsencrypt
* SWARM : enable if use this reverse with docker swarm mode (default : disable)
* TLS_VERSION : Choose tls version separate by space (default : "TLSv1.1 TLSv1.2")
* CIPHER_SUITE : Choose cipher suite (default : "EECDH+CHACHA20:EECDH+AESGCM")
* ECDH_CURVE : Choose ecdh curve (default : "X25519:P-521:P-384")

### Volumes
* /nginx/ssl : For certificate persistance
* /nginx/sites_enabled : Warning, this file can be delete if restart container
* /nginx/path.d : Warning, this file can be delete if restart container 
* /nginx/custom_sites : For create your own sites

### Ports
* 8080
* 8443

## Usage
### Labels
| Label Name | Description | default | value |
| ---------- | ----------- | ------- | ----- |
| reverse.frontend.domain | Domain Name for this service | mydomain.local | valid domain name (For multiple domains, separate by comma) |
| reverse.frontend.path | Domain path (warning, no rewrite url) | / | valid path, with / |
| reverse.frontend.auth | For auth basic | none | user:encryptpassword (For multiple auth, separate by comma) |
| reverse.frontend.ssltype | Choose ssl type | ec384 | rsa2048, rsa4096, rsa8192, ec256 or ec384 |
| reverse.frontend.domain\_max\_body\_size | Choose max size upload | 200M | Numeric value with unit (K,M,G,T) |
| reverse.frontend.hsts | Enable HSTS | enable | enable or disable |
| reverse.frontend.ocsp | Enable OCSP | enable | enable or disable |
| reverse.frontend.ct | Generate CT for certificate | disable | enable or disable |
| reverse.frontend.ssl | Generate letsencrypt certificate | disable | enable or disable |
| reverse.backend.port | Port use by container | 8080 | Valid port number |

More labels soon !!!

### Gen manuel cert
```shell
$ docker exec -ti container_name gen_manuel_ssl sub.domain.tld rsa4096
```

### Launch
#### First launch another container
For exemple, I launch lutim container :
```shell
$ docker run -d \
    --name lutim \
    --label reverse.frontend.domain=sub.domain.com \
    --label reverse.frontend.path=lutim \
    --label reverse.frontend.auth=USER:$(openssl passwd -crypt PASSWORD) \
    --label reverse.frontend.ssltype=ec256 \
    --label reverse.frontend.ssl=enable \
    --label reverse.backend.port=8181 \
    -v /docker/config/lutim/data:/data \
    -v /docker/data/lutim:/lutim/files \
    -e UID=1001 \
    -e GID=1001 \
    -e WEBROOT=/lutim \
    -e SECRET=$(date +%s | md5sum | head -c 32) \
    -e CONTACT=contact@domain.com \
    -e MAX_FILE_SIZE=250000000 \
    xataz/lutim
```


#### Launch reverse-nginx
```shell
docker run -d \
	-p 80:8080 \
	-p 443:8443 \
    --name reverse \
    -e EMAIL=me@mydomain.com \
    -v /var/run/docker.sock:/var/run/docker.sock \
	xataz/reverse-nginx
```

URI Access : https://sub.domain.com/lutim
