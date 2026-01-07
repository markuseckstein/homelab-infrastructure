#!/bin/bash
set -e

echo "=== Installing Docker ==="
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
systemctl enable --now docker

echo "=== Creating newt directory and .env file ==="
mkdir -p /root/newt
chmod 700 /root/newt

cat > /root/newt/.env <<'ENVFILE'
PANGOLIN_ENDPOINT=pangolin.markuseckstein.de
NEWT_ID=${newt_id}
NEWT_SECRET=${newt_secret}
ENVFILE

chmod 600 /root/newt/.env

echo "=== Starting newt container ==="
docker run -d \
  --name newt \
  --env-file /root/newt/.env \
  fosrl/newt:latest

echo "=== Done ==="
