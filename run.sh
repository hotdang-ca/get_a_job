#!/bin/sh

docker run \
  --expose 80 \
  --network=nginx-proxy \
  -d \
  --restart always \
  --name getajob-web \
  -e VIRTUAL_HOST=getajob.fourandahalfgiraffes.ca \
  -e LETSENCRYPT_HOST=getajob.fourandahalfgiraffes.ca \
  -e LETSENCRYPT_EMAIL=james+getajob@hotdang.ca \
  getajob-web
