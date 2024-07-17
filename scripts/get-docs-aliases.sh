#!/usr/bin/env bash

# Script to generate aliases for the documentation.
# This initial verstion only generates the following aliases:
#
# Non Production Releases:
# * latest-pre
#
# Production Releases:
# * latest
# * latest-prod

# This script was created as a part of a framework that will allow
# for future versions to include aliases for major and minor versions, e.g.:
# * latest-v1
# * latest-v1.4
# * latest-v2

# Currently, this script relies on the following env variables that have been
# defined in the GitLab CI pipeline

# CI_COMMIT_REF_NAME - The branch name for the currently running branch.
# PRE_RELEASE_BRANCHES_PATTERN - The regex for the pre release branches
# RELEASE_BRANCHES_PATTERN - The regex for the release branches

# If these env vars are not set, or the regexes do not match, no alias namers will be returned.

# The regexes defined in the GitLab CI definition include leading and trailing slashes.
# This removes them so they can be used in this bash script
PRE_RELEASE_BRANCHES_PATTERN=$(echo ${PRE_RELEASE_BRANCHES_PATTERN}| sed 's:^/::; s:/$::')
RELEASE_BRANCHES_PATTERN=$(echo ${RELEASE_BRANCHES_PATTERN}| sed 's:^/::; s:/$::')


if [[ "${CI_COMMIT_REF_NAME}" =~ ${PRE_RELEASE_BRANCHES_PATTERN} ]]; then
    echo "latest-pre"
elif [[ "${CI_COMMIT_REF_NAME}" =~ ${RELEASE_BRANCHES_PATTERN} ]]; then
    echo "latest latest-prod"
fi
