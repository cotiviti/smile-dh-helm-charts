#!/usr/bin/env bash

# Script to prepare release...
# * Bump chart versions
# * Regenerate docs with correct version
# * Update the `expected output` files
# * Package the Helm Charts

SRC_DIR="${1}"
NEW_VER="${2}"

# echo "Running bump script to bump charts to version ${NEW_VER}"

CHARTS_DIR="${SRC_DIR}/main/charts"

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

./scripts/check-outputs.sh -u ./src
# echo "Updating Helm Docs..."
helm-docs --chart-search-root=src/main/charts --template-files=./_templates.gotmpl --template-files=README.md.gotmpl
# echo "Packaging Helm Charts..."
helm package src/main/charts/*
