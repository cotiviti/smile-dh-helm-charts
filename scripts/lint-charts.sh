#!/usr/bin/env bash

# Script to run `helm template` on all charts.
# Always use this before checking chart outputs, to make sure the Helm Chart is functioning correctly

SRC_DIR="."

while getopts "s:d" flag; do
case "$flag" in
    s) SRC_DIR=$OPTARG;;
    d) DEBUG=1;;
    *) ;;
esac
done

# shellcheck disable=SC2001 # Need re match for multiple trailing slashes
SRC_DIR="$(echo "${SRC_DIR}" | sed 's:/*$::')"

CHARTS_DIR="${SRC_DIR}"/main/charts

scripts/prepare-chart-dependencies.sh -s ./src

ERROR=0

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

debugPrint() {
    if [ "$DEBUG" == "1" ]; then
        # Disabling as we are passing in first param as string that uses %s anyways
        # shellcheck disable=2059
        printf "$@"
    fi
}

ERROR=0
for CHART in ${CHARTS}; do
    CURRENT_CHART_DIR="${CHARTS_DIR}/${CHART}"

    debugPrint "Linting %s chart with default values file\n" "${CHART}"
    HELM_OUTPUT=$(helm lint --set unitTesting=true "${CURRENT_CHART_DIR}")
    HELM_RES=$?
    if [ "${HELM_RES}" != "0" ]; then
        printf "Linting failed for %s chart using default values file\n\n" "${CHART}"
        printf "Error: %s\n\n" "${HELM_OUTPUT}"
    fi
done

exit ${ERROR}
