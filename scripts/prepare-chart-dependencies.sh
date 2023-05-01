#!/usr/bin/env bash

# Script to prepare charts by installing the Smile DH common dependency library chart
#
# You need to run this script before running other commands such as `helm lint` or `helm template`.

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
        CHART="$(basename "${DIR}")"
        # Only include Application Helm Charts
        # Also temporarily disable chart dependency for smilecdr chart
        if [ "smilecdr" == "${CHART}" ]; then continue; fi
        if [ "$(grep "^type:" "${DIR}/Chart.yaml" | grep -c "application" )" -ne 0 ]; then
            CHARTS="${CHARTS} ${CHART}"
        fi
    fi
done <   <(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

for CHART in ${CHARTS}; do
    # printf ${CHART}
    CURRENT_CHART_DIR="${CHARTS_DIR}/${CHART}"
    # Add/update sdh-common dependency chart.

    # This is hard coded rather than using `helm dependency build`, because
    # the defined dependency will pull from the repo, rather than the current
    # code being worked on. There is only a single 'common' chart so this
    # **should** never change.

    mkdir -p "${CURRENT_CHART_DIR}"/charts
    if [ -d "${CURRENT_CHART_DIR}"/charts/sdh-common ]; then
        rm -r "${CURRENT_CHART_DIR}"/charts/sdh-common
    fi
    cp -rp "${CHARTS_DIR}"/sdh-common "${CURRENT_CHART_DIR}"/charts
done
