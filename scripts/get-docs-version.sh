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

# If the version contains `pre`, `next`, `beta` or `alpha` return that, otherwise only return the minor version

# TODO: Fix the regex to prevent false matches, even though VERY unlikely.
if [[ "${FULL_VERSION}" =~ pre ]]; then
  # Just strip the pre version number from the current major prerelease
  echo "${FULL_VERSION}" | sed -E 's/pre\.([0-9]+)$/pre/'
elif [[ "${FULL_VERSION}" =~ next-major ]]; then
  # Just strip the next version number from the next-major prerelease
  echo "${FULL_VERSION}" | sed -E 's/next-major\.([0-9]+)$/next-major/'
elif [[ "${FULL_VERSION}" =~ beta ]]; then
  # Just strip the beta version number from the beta prerelease
  echo "${FULL_VERSION}" | sed -E 's/beta\.([0-9]+)$/beta/'
elif [[ "${FULL_VERSION}" =~ alpha ]]; then
  # Just strip the alpha version number from the alpha prerelease
  echo "${FULL_VERSION}" | sed -E 's/alpha\.([0-9]+)$/alpha/'
else
  # Just return the minor version
  echo "${FULL_VERSION}" | sed -E 's/(^[v]?[0-9]+\.[0-9]+).*/\1/'
fi

# # Just return the major.minor version
# echo "${FULL_VERSION}" | sed -E 's/(^[v]?[0-9]+\.[0-9]+).*/\1/'
