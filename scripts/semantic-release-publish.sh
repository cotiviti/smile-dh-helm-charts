#!/usr/bin/env bash

# Script to release the Helm Charts to appropriate channel

NEW_VER="${1}"
CHANNEL="${2:-stable}"


echo "Publishing Helm Chart version ${NEW_VER} to ${CHANNEL} release channel..."

./scripts/publish-charts.sh gitlab-ci-token:$CI_JOB_TOKEN ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api ${CHANNEL} *.tgz

echo "Helm Chart version ${NEW_VER} successfully published to ${CHANNEL} release channel!"
