#!/bin/sh
set -ex

sudo ./alpine-make-rootfs \
	--packages 'curl openssl openssh-client iptables xz' \
	--script-chroot \
	rootfs.tar.gz alpine.sh
