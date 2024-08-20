#!/usr/bin/env bash

# Script to prepare and perform release...
# * Bump chart versions
# * Regenerate docs with correct version
# * Update the `expected output` files
# * Package the Helm Charts

SRC_DIR="${1}"
NEW_VER="${2}"
CHANNEL="${3:-stable}"

# echo "Running bump script to bump charts to version ${NEW_VER}"

echo "${NEW_VER}" > .VERSION

# Update `version` in `Chart.yaml`` for all charts.

CHARTS_DIR="${SRC_DIR}/main/charts"

echo "Preparing Helm Chart version ${NEW_VER} for ${CHANNEL} release channel..."

while IFS= read -r -d '' DIR
do
    # Only include valid Helm Chart directories
    if [ -f "${DIR}/Chart.yaml" ]; then
        # echo "Bumping version for ${DIR}"
        # echo "Existing:"
        # grep "version" "${DIR}/Chart.yaml"
        sed -Ei "s/(^version: ).*$/\1$NEW_VER/g" "${DIR}/Chart.yaml"
        # echo "After:"
        # grep "version" "${DIR}/Chart.yaml"
    fi
done <   <(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

echo "${NEW_VER}" > .VERSION

# Update helm unit test outputs for new version
echo "Updating Helm Chart Unit Tests..."
./scripts/check-outputs.sh -u -s ./src

echo "Updating Helm Docs to include correct version..."
helm-docs --chart-search-root=src/main/charts --template-files=helm-docs/_templates.gotmpl --template-files=README.md.gotmpl

echo "Packaging Helm Charts..."
helm package src/main/charts/*

echo "Cleaning Helm Charts for repository... (Removing dependency sub-charts)"
./scripts/clean-charts.sh -s ./src
