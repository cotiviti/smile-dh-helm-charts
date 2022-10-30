#!/usr/bin/env bash

# Script to run `helm template` on all charts.
# Always use this before checking chart outputs, to make sure the Helm Chart is functioning correctly


while getopts "d" flag; do
case "$flag" in
    d) DEBUG=1;;
    *) ;;
esac
done

SRC_DIR="${*:$OPTIND:1}"
# SRC_DIR="${1}"
CHARTS_DIR="${SRC_DIR}/main/charts"
CHART_TESTS_DIR="${SRC_DIR}/test/helm-output"
ERROR=0

while IFS= read -r -d '' DIR
do
    # Only include valid Helm Chart directories
    if [ -f "${DIR}/Chart.yaml" ]; then
        CHARTS="${CHARTS} $(basename "${DIR}")"
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
    CURRENT_CHART_TESTS_DIR="${CHART_TESTS_DIR}/${CHART}"
    COUNT=0
    if [ -d "${CURRENT_CHART_TESTS_DIR}" ]; then
        while IFS= read -r -d '' DIR
        do
            if [ -f "${DIR}/values.yaml" ]; then
                (( COUNT++ ))
                TEST_NAME=$(basename "${DIR}")
                if [ -f "${DIR}/custom-modules.yaml" ]; then
                    debugPrint "Linting %s chart with %s values file and custom modules file\n" "${CHART}" "${TEST_NAME}"
                    helm lint -f "${DIR}"/values.yaml --set-file externalModuleDefinitions.custom="${DIR}"/custom-modules.yaml "${CHARTS_DIR}"/"${CHART}"
                    err=$?
                else
                    debugPrint "Linting %s chart with %s values file\n" "${CHART}" "${TEST_NAME}"
                    helm lint -f "${DIR}"/values.yaml "${CHARTS_DIR}"/"${CHART}"
                    err=$?
                fi

                if [ $err -ne 0 ]; then
                    printf "helm lint failed for %s chart using %s values file" "${CHART}" "${TEST_NAME}"
                    ERROR=1
                fi
            fi
        done <   <(find "${CURRENT_CHART_TESTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    if [ "${COUNT}" == "0" ]; then
        printf "There are no tests defined for %s Helm Chart" "${CHART}"
        ERROR=1
    fi
done

exit ${ERROR}
