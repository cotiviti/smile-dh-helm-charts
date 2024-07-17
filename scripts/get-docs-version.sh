#!/usr/bin/env bash

# Script to derive docs version from provided tag

# Usage:
# get-docs-version.sh tagName
# e.g:
# get-docs-version.sh 1.2.3

# If the version ends in `pre.nnn` then it will strip the prerelease version.
# e.g:
# get-docs-version.sh 1.2.3-pre.65
# will return:
# 1.2.3-pre

TAG="${1}"

FULL_VERSION=${TAG}

# If the version contains `pre`, return that, otherwise return the minor version

if [[ "${FULL_VERSION}" =~ pre ]]; then
  # Just strip the pre version number from the pre-release
  echo "${FULL_VERSION}" | sed -E 's/pre\.([0-9]+)$/pre/'
else
  # Just return the minor version
  echo "${FULL_VERSION}" | sed -E 's/(^[v]?[0-9]+\.[0-9]+).*/\1/'
fi
