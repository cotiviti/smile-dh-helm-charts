#!/usr/bin/env bash

# Script to compare `helm template` output with expected output.
# Use this to make ensure that cosmetic code changes (Typos, doc changes, refactoring etc) do not change the generated output

# This script renders all charts in `src/main/charts`, using respective values files from `src/test/helm-output/<chartname>/<dir>/values.yaml`
# It semantically compares the output `with src/test/helm-output/<chartname>/<dir>/output.yaml`.

# If you are making functional changes to the charts, call the script with the -u flag to update the "expected output" files.

SRC_DIR="."
TEST_SELECTOR=""

while getopts "ufs:t:d" flag; do
case "$flag" in
    s) SRC_DIR=$OPTARG;;
    t) TEST_SELECTOR=$OPTARG;;
    u) UPDATE=1;;
    f) FORCE_UPDATE=1;;
    d) DEBUG_MODE=1;;
    *) ;;
esac
done

# shellcheck disable=SC2001 # Need re match for multiple trailing slashes
SRC_DIR="$(echo "${SRC_DIR}" | sed 's:/*$::')"

CHARTS_DIR="${SRC_DIR}"/main/charts
CHART_TESTS_DIR="${SRC_DIR}"/test/helm-output

scripts/prepare-chart-dependencies.sh -s ./src

DEBUG_OPT=""
if [ "${DEBUG_MODE}" == "1" ]; then
    echo "************** WARNING **************"
    echo "*                                   *"
    echo "***   You are using DEBUG mode!   ***"
    echo "*                                   *"
    echo "* This may render broken manifests! *"
    echo "* Only use for troubleshooting      *"
    echo "* rendering problems                *"
    echo "*                                   *"
    echo "* Press a key to continue...        *"
    echo "*************************************"
    read -r
    FORCE_UPDATE=1
    DEBUG_OPT="--debug"
    DEBUG_OPT_MSG="in debug mode "
fi

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

ERROR=0
for CHART in ${CHARTS}; do
    # printf ${CHART}
    CURRENT_CHART_TESTS_DIR="${CHART_TESTS_DIR}/${CHART}"
    CURRENT_CHART_DIR="${CHARTS_DIR}/${CHART}"

    COUNT=0
    TESTS_RUN_COUNT=0
    if [ -d "${CURRENT_CHART_TESTS_DIR}" ]; then
        while IFS= read -r -d '' DIR
        do
            DO_UPDATE=0
            if [ -f "${DIR}/testconfig.yaml" ]; then
                DIR_NAME=$(basename "${DIR}")
                TESTS_COUNT=0
                TESTS_EXIST="$(yq -ojson "${DIR}/testconfig.yaml" | jq -rc '. | has("tests")')"
                if [ "${TESTS_EXIST}" == "true" ]; then
                    TESTS_COUNT=$(yq -ojson "${DIR}/testconfig.yaml" | jq -rc '.tests | length')
                fi

                if [ "${TESTS_COUNT}" -gt 0 ]; then
                    TESTS="$(yq -ojson "${DIR}/testconfig.yaml" | jq -rc '.tests | keys[]')"
                    for TEST_NAME in ${TESTS}; do
                        (( COUNT++ ))
                        if [ "${TEST_SELECTOR}" != "" ]; then
                            # If TEST_SELECTOR is specified:
                            # * TEST_SELCETOR can have multiple substrings to match.
                            # * Only run test in the following condition
                            # * Substring must be inside chart name, or testdir name or test name in testconfig.yaml.
                            # * Matching is case insensitive
                            # * ALL substrings in TEST_SELECTOR must match

                            MISMATCH=0
                            for test_string in ${TEST_SELECTOR}; do
                                if [ "${CHART#*"$test_string"}" != "$CHART" ] || \
                                   [ "${DIR_NAME#*"$test_string"}" != "$DIR_NAME" ] || \
                                   [ "${TEST_NAME#*"$test_string"}" != "$TEST_NAME" ]; then
                                    # Matched with combined tests... Do nothing
                                    :
                                else
                                    # This selector string did not match, so don't check any more
                                    # printf "%s didn't match %s\n" "${TEST_SELECTOR}" "${TEST_NAME}"
                                    MISMATCH=1
                                    continue
                                fi
                            done
                            if [ ${MISMATCH} -eq 0 ]; then
                                RUN_TEST=1
                                printf "Running check/update. Chart: \"%s\" Test: \"%s.%s\" based on selector \"%s\"\n" "${CHART}" "${DIR_NAME}" "${TEST_NAME}" "${TEST_SELECTOR}"
                            else
                                RUN_TEST=0
                            fi
                        else
                            RUN_TEST=1
                        fi

                        if [ ${RUN_TEST} -eq 0 ]; then
                            continue
                        fi

                        (( TESTS_RUN_COUNT++ ))
                        HELMOPTS=""
                        if [ "$(yq -ojson "${DIR}/testconfig.yaml" | jq -rc --arg TEST_NAME "${TEST_NAME}" '.tests[$TEST_NAME] | has("outputFile")')" == "true" ]; then
                            OUTFILE=$(yq -ojson "${DIR}/testconfig.yaml" | jq -rc --arg TEST_NAME "${TEST_NAME}" '.tests[$TEST_NAME]["outputFile"]')
                        else
                            OUTFILE=output.yaml
                        fi

                        if [ "$(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["valueFiles"] | length')" -gt 0 ]; then
                            for VALUES_FILE in $(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["valueFiles"][]'); do
                                HELMOPTS="${HELMOPTS} -f ${DIR}/${VALUES_FILE}"
                            done
                        else
                            HELMOPTS="${HELMOPTS} -f ${DIR}/values.yaml"
                        fi

                        if [ "$(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["set"] | length')" -gt 0 ]; then
                            for SET in $(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["set"][]'); do
                                KEY=$(echo "${SET}" | jq -rc '.key')
                                VALUE=$(echo "${SET}" | jq -rc '.value')
                                HELMOPTS="${HELMOPTS} --set ${KEY}=${VALUE}"
                            done
                        fi

                        if [ "$(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["setFile"] | length')" -gt 0 ]; then
                            for SET_FILE in $(yq -ojson "${DIR}/testconfig.yaml" | jq --arg TEST_NAME "${TEST_NAME}" -rc '.tests[$TEST_NAME]["setFile"][]'); do
                                KEY=$(echo "${SET_FILE}" | jq -rc '.key')
                                FILENAME=$(echo "${SET_FILE}" | jq -rc '.fileName')
                                HELMOPTS="${HELMOPTS} --set-file ${KEY}=${DIR}/${FILENAME}"
                            done
                        fi
                        # TODO: Check if HELMOPTS or OUTFILE is empty, and show error

                        if [ -f "${DIR}/${OUTFILE}" ]; then
                            # shellcheck disable=SC2086 # Intended splitting of HELMOPTS
                            HELM_OUTPUT=$(helm template --namespace default ${HELMOPTS} ${CURRENT_CHART_DIR} | sed '/^.*helm\.sh\/chart.*$/d' )
                            HELM_RES=$?
                            if [ "${HELM_RES}" != "0" ]; then
                                printf "Rendering template failed for test: %s.%s\n" "${DIR_NAME}" "${TEST_NAME}"
                            fi
                            DYFF_TEXT=$(echo "${HELM_OUTPUT}" | dyff between --omit-header --set-exit-code --ignore-order-changes "${DIR}"/"${OUTFILE}" -)
                            DYFF_RES=$?

                            if [ "${DYFF_RES}" != "0" ]; then
                                if [ "${UPDATE}" == "1" ]; then
                                    DO_UPDATE=1
                                else
                                    printf "Output differs for %s chart using %s values file." "${CHART}" "${TEST_NAME}"
                                    printf "%s" "${DYFF_TEXT}"
                                    printf "For prettier output, you can run the following:\n"
                                    printf "  helm template --namespace default %s %s | sed '/^.*helm\.sh\/chart.*$/d' | dyff between %s/%s -\n\n" "${HELMOPTS}" "${CURRENT_CHART_DIR}" "${DIR}" "${OUTFILE}"
                                    ERROR=1
                                fi
                            fi
                        else
                            if [ "${UPDATE}" == "1" ]; then
                                DO_UPDATE=1
                            else
                                printf "  There is no expected output file for the %s Helm Chart using %s testconfig.yaml file.\n\n" "${CHART}" "${TEST_NAME}"
                                ERROR=1
                            fi
                        fi

                        if [ "${DO_UPDATE}" == "1" ] || [ "${FORCE_UPDATE}" == "1" ]; then
                            printf "Rendering new expected output %sfor %s chart using %s.%s from testconfig.yaml file\n" "${DEBUG_OPT_MSG}" "${CHART}" "${DIR_NAME}" "${TEST_NAME}"
                            if [ "${DEBUG_MODE}" == "1" ]; then
                                printf "Helm command: \n\n helm template %s --namespace default %s %s > %s/%s\n\n" "${DEBUG_OPT}" "${HELMOPTS}" "${CURRENT_CHART_DIR}" "${DIR}" "${OUTFILE}"
                            fi
                            # shellcheck disable=SC2086 # Intended splitting of HELMOPTS
                            helm template ${DEBUG_OPT} --namespace default ${HELMOPTS} ${CURRENT_CHART_DIR} > "${DIR}"/"${OUTFILE}"

                            if [ ! $? ]; then
                                printf " Rendering failed. Did the linting pass?"
                                ERROR=2
                            else
                                # Need to run `sed` this way so it works on Mac workstations as well as on Linux GitLab runners
                                # This `sed` command removes any trailing spaces
                                sed -i.bak 's/[[:space:]]*$//' "${DIR}"/"${OUTFILE}"
                                rm "${DIR}"/"${OUTFILE}".bak
                                # This `sed` command removes the `helm.sh/chart` label from outputs.
                                sed -i.bak '/^.*helm\.sh\/chart.*$/d' "${DIR}"/"${OUTFILE}"
                                rm "${DIR}"/"${OUTFILE}".bak
                            fi
                        fi
                    done
                fi
            fi
        done <   <(find "${CURRENT_CHART_TESTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)
        if [ "${TEST_SELECTOR}" != "" ] && \
           [ "${TESTS_RUN_COUNT}" == "0" ]; then
            printf "Selector \"%s\" didn't match any tests for chart \"%s\"\n" "${TEST_SELECTOR}" "${CHART}"
        fi
    fi
    if [ "${COUNT}" == "0" ]; then
        printf "There are no tests defined for \"%s\" Helm Chart\n" "${CHART}"
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
