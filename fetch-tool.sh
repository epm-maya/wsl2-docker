#!/bin/sh
set -ex

rm alpine-make-rootfs || true
rm -rf alpine-make-rootfs-d || true
git clone --depth 1 https://github.com/alpinelinux/alpine-make-rootfs.git alpine-make-rootfs-d
cp alpine-make-rootfs-d/alpine-make-rootfs .

