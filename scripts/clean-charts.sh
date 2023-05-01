#!/usr/bin/env bash

# Script to clean charts by removing the dependency subcharts
#

SRC_DIR="src"

while getopts "s:" flag; do
case "$flag" in
    s) SRC_DIR=$OPTARG;;
    *) ;;
esac
done

# shellcheck disable=SC2001 # Need re match for multiple trailing slashes
SRC_DIR="$(echo "${SRC_DIR}" | sed 's:/*$::')"

CHARTS_DIR="${SRC_DIR}"/main/charts

while IFS= read -r -d '' DIR
do
    # Only include valid Helm Chart directories
    if [ -f "${DIR}/Chart.yaml" ]; then
        # Only include Application Helm Charts
        if [ "$(grep "^type:" "${DIR}/Chart.yaml" | grep -c "application" )" -ne 0 ]; then
            CHARTS="${CHARTS} $(basename "${DIR}")"
        fi
    fi
done <   <(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

for CHART in ${CHARTS}; do
    # printf ${CHART}
    CURRENT_CHART_DIR="${CHARTS_DIR}/${CHART}"
    # Delete any subcharts.

    if [ -d "${CURRENT_CHART_DIR}"/charts ]; then
        rm -r "${CURRENT_CHART_DIR}"/charts
    fi
done
