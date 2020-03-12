set -ex

DOCKERVER='19.03.8'

echo "build in alpine (docker-${DOCKERVER})"

install -D -m 755 docker.sh /usr/local/sbin/docker.sh
install -D -m 755 generate-tls-key.sh /usr/local/sbin/generate-tls-key.sh

mkdir -p /root
mkdir -p /var/lib/wsl2-docker
mkdir -p /usr/local/bin

cd /root

curl -fLo docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVER}.tgz"
tar xzf docker.tgz
mv docker/* /usr/local/bin/
rm -rf docker
rm docker.tgz

addgroup -S docker

echo "DONE"
