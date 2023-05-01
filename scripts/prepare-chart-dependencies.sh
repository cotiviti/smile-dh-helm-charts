#!/usr/bin/env sh

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
CHART_DIRS="$(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d )"

# while IFS= read -r DIR
for DIR in ${CHART_DIRS}; do
    # Only include valid Helm Chart directories
    if [ -f "${DIR}/Chart.yaml" ]; then
        CHART="$(basename "${DIR}")"
        # Only include Application Helm Charts
        # Also temporarily disable chart dependency for smilecdr chart
        if [ "smilecdr" = "${CHART}" ]; then continue; fi
        if [ "$(grep "^type:" "${DIR}/Chart.yaml" | grep -c "application" )" -ne 0 ]; then
            CHARTS="${CHARTS} ${CHART}"
        fi
    fi
done

HELM_OUTPUT="$(helm package "${CHARTS_DIR}"/sdh-common)"
HELM_RES=$?
if [ "${HELM_RES}" != "0" ]; then
    printf "Rendering template failed for test: %s.%s\n" "${DIR_NAME}" "${TEST_NAME}"
else
    SDH_COMMON_FILE="$(echo "${HELM_OUTPUT}" | awk '{print $NF}' )"
    if [ ! -f "${SDH_COMMON_FILE}" ]; then
        printf "Could not get the correct output from Helm when rendering the common library.\n"
        printf "Filename was:\n%s\nbut it does not exist. Exciting!\n\n" "${SDH_COMMON_FILE}"
        exit
    fi
fi


for CHART in ${CHARTS}; do
    # printf ${CHART}
    CURRENT_CHART_DIR="${CHARTS_DIR}/${CHART}"
    # Add/update sdh-common dependency chart.

    # This is hard coded rather than using `helm dependency build`, because
    # the defined dependency will pull from the repo, rather than the current
    # code being worked on. There is only a single 'common' chart so this
    # **should** never change.

    if [ -d "${CURRENT_CHART_DIR}"/charts ]; then
        rm -r "${CURRENT_CHART_DIR}"/charts
    fi
    mkdir -p "${CURRENT_CHART_DIR}"/charts
    cp -rp "${SDH_COMMON_FILE}" "${CURRENT_CHART_DIR}"/charts/
done

rm "${SDH_COMMON_FILE}"
