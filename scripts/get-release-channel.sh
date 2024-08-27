#!/usr/bin/env bash

# Script to determine the release channel from the branch name

# If we are not on an appropriate branch, then the script will error due to CI misconfiguration.
# Make sure this script only runs on one of the following branches:

# Stable branches
# * `main` - Current stable major release
# * `release-*.x` - Maintenance releases

# Prerelease branches
# * `pre-release` - "-pre.n" - Next minor release for current stable major release, n
# * `next` (Same as `pre-release`, but this may be implemented in the future)
# * `next-major` - "-next.n" - Next major release, n+1
# * `beta` - "-beta.n" - Future major release, n+2
# * `alpha` - "-alpha.n" - Future major release, n+3

# Note that this needs to match the configuration in the Semantic Release configuration (.releaserc)

BRANCH="${1}"
CHANNEL=""

# If the version contains `pre`, `next`, `beta` or `alpha` return that, otherwise only return the minor version

if [[ "${BRANCH}" =~ ^(main|release-[1-9][0-9]*\.x)$ ]]; then
  CHANNEL='stable'
elif [[ "${BRANCH}" =~ ^(pre-release|next)$ ]]; then
  CHANNEL='pre'
elif [[ "${BRANCH}" =~ ^next-major$ ]]; then
  CHANNEL='next-major'
elif [[ "${BRANCH}" =~ ^beta$ ]]; then
  CHANNEL='beta'
elif [[ "${BRANCH}" =~ ^alpha$ ]]; then
  CHANNEL='alpha'
fi

if [ -z "${CHANNEL}" ]; then
    >&2 echo -e "Not running on a valid branch that has a channel.\n\nBranch: ${BRANCH}"
    exit 1
else
    echo "${CHANNEL}"
fi
