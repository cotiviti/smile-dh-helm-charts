#!/usr/bin/env bash

# Script to upload charts to a chart repo using curl
# Based on https://docs.gitlab.com/ee/user/packages/helm_repository/#use-cicd-to-publish-a-helm-package

# Usage:
# publish-charts.sh <user> <url> <channel> charts
# e.g:
# publish-charts.sh gitlab-ci-token:heguyewbu https://url.to/path/to/packages/helm/api stable|devel *.tgz

USER="${1}"; shift
URL_BASE="${1}"; shift
CHANNEL="${1}"; shift
for CHART in "$@"
do
  curl --request POST --user "${USER}" --form "chart=@${CHART}" "${URL_BASE}/${CHANNEL}/charts"
done
