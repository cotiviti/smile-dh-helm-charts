#!/usr/bin/env bash

# Script to compare `helm template` output with expected output.
# Use this to make ensure that cosmetic code changes (Typos, doc changes, refactoring etc) do not change the generated output

# This script renders all charts in `src/main/charts`, using respective values files from `src/test/helm-output/<chartname>/<dir>/values.yaml`
# It semantically compares the output `with src/test/helm-output/<chartname>/<dir>/output.yaml`.

# If you are making functional changes to the charts, call the script with the -u flag to update the "expected output" files.

while getopts "u" flag; do
case "$flag" in
    u) UPDATE=1;;
    *) ;;
esac
done

SRC_DIR="${*:$OPTIND:1}"
CHARTS_DIR="${SRC_DIR}/main/charts"
CHART_TESTS_DIR="${SRC_DIR}/test/helm-output"

while IFS= read -r -d '' DIR
do
    # Only include valid Helm Chart directories
    if [ -f "${DIR}/Chart.yaml" ]; then
        CHARTS="${CHARTS} $(basename "${DIR}")"
    fi
done <   <(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

ERROR=0
for CHART in ${CHARTS}; do
    # printf ${CHART}
    CURRENT_CHART_TESTS_DIR="${CHART_TESTS_DIR}/${CHART}"
    COUNT=0
    if [ -d "${CURRENT_CHART_TESTS_DIR}" ]; then
        while IFS= read -r -d '' DIR
        do
            DO_UPDATE=0
            if [ -f "${DIR}/values.yaml" ]; then
                (( COUNT++ ))
                TEST_NAME=$(basename "${DIR}")
                # printf "Comparing helm template output with expected output for ${CHART} chart using ${TEST_NAME} values file"
                if [ -f "${DIR}/output.yaml" ]; then
                    # printf "  Do tha test!"
                    DYFF_TEXT=$(helm template -f "${DIR}"/values.yaml "${CHARTS_DIR}"/"${CHART}" | dyff between --omit-header --set-exit-code "${DIR}"/output.yaml -)
                    DYFF_RES=$?
                    if [ "${DYFF_RES}" != "0" ]; then
                        if [ "${UPDATE}" == "1" ]; then
                            DO_UPDATE=1
                        else
                            printf "Output differs for %s chart using %s values file." "${CHART}" "${TEST_NAME}"
                            printf "%s" "${DYFF_TEXT}"
                            ERROR=1
                        fi
                    fi
                else
                    if [ "${UPDATE}" == "1" ]; then
                        DO_UPDATE=1
                    else
                        printf "  There is no expected output file for the %s Helm Chart using %s values file." "${CHART}" "${TEST_NAME}"
                        ERROR=1
                    fi
                fi
                if [ "${DO_UPDATE}" == "1" ]; then
                    printf "Rendering new expected output for %schart using %s values file" "${CHART}" "${TEST_NAME}"
                    helm template -f "${DIR}"/values.yaml "${CHARTS_DIR}"/"${CHART}" > "${DIR}"/output.yaml
                    if [ ! $? ]; then
                        printf " Rendering failed. Did the linting pass?"
                        ERROR=2
                    fi
                fi
            fi
        done <   <(find "${CURRENT_CHART_TESTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    if [ "${COUNT}" == "0" ]; then
        printf "There are no tests defined for %s Helm Chart" "${CHART}"
        ERROR=1
    fi
done

if [ "${ERROR}" == "1" ]; then
    printf "\nFix the rendering problem, or run the script again with the -u flag to create\n"
    printf "and review the expected output files and then check again like so:\n"
    printf "\n  %s -u %s\n" "${0}" "${SRC_DIR}"
    exit 1
elif [ "${ERROR}" == "2" ]; then
    printf "\nFailed to render new expected output files with helm template."
    exit 1
fi
