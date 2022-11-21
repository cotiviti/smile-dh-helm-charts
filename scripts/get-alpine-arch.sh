#!/usr/bin/env sh

# Script to determine the current running architecture and return a more commonly used name
# Used for installing helm-docs. From https://github.com/norwoodj/helm-docs/releases/tag/v1.11.0,
# the arch needs to be one of:
# * arm64
# * armv6
# * armv7
# * x86_64
#
# Installing helm itself (Required for updating expected outputs) is different, because of course.
# From: https://github.com/helm/helm/releases/tag/v3.10.1
# * arm64
# * amd64 (Instead of x86_64)
#
# Alpine linux reports ARM architectures differently (from: https://wiki.alpinelinux.org/wiki/Architecture)
# Like so...
# * aarch64 (arm64) - Also known as 64 bit ARM or ARMv8
# * armhf (armv6)
# * armv7 (armv7) - Unchanged
# * x86_64 (x86_64) - Unchanged

TARGET=${1}

ARCH=$(uname -m)
ALT_ARCH=${ARCH}
case $ARCH in
    "aarch64")
        ALT_ARCH="arm64"
        ;;
    "armhf")
        ALT_ARCH="armv6"
        ;;
esac

if [ "${TARGET}" = "helm" ] && [ "${ARCH}" = "x86_64" ]; then
    ALT_ARCH="amd64"
fi

printf "%s" ${ALT_ARCH}
