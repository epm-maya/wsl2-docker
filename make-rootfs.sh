#!/bin/sh
set -ex

sudo ./alpine-make-rootfs \
	--packages 'curl openssl openssh-client iptables xz' \
	--script-chroot \
	rootfs.tar.gz -- content/alpine.sh

sha256sum rootfs.tar.gz > rootfs.tar.gz.sha256

cat rootfs.tar.gz.sha256
