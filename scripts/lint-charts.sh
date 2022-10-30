#!/usr/bin/env bash

# Script to run `helm template` on all charts.
# Always use this before checking chart outputs, to make sure the Helm Chart is functioning correctly

SRC_DIR="${1}"
CHARTS_DIR="${SRC_DIR}/main/charts"
ERROR=0

while IFS= read -r -d '' CHART_DIR
do
    # Only run helm lint in valid Helm Chart directories
    if [ -f "${CHART_DIR}/Chart.yaml" ]; then
        # printf "linting %s chart\n" "$(basename "${CHART_DIR}")"
        helm lint "${CHART_DIR}"
        err=$?
        # printf "err: %s\n" "${err}"
        if [ $err -ne 0 ]; then
            printf "helm lint failed for %s chart" "$(basename "${CHART_DIR}")"
            ERROR=1
        fi
    fi
done <   <(find "${CHARTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

exit ${ERROR}
