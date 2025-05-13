#!/usr/bin/env bash

# Script to prepare changelog
# We want to have a changelog per major version to that it does not get too unwieldy
# The semantic release `@semantic-release/changelog` plugin does not allow setting changelog filename using environment variables.
# So instead, this script will do the following:

# It creates a per-version, per-channel changelog file which gets updated by semantic release.
# This file is then copied to the main per-version changelog for inclusion in the docs.
# The result of this is that the per-version changelog will get all the changes in a given channel.
# When a version is promoted to a new channel, then it will start with a fresh changelog file,
#  but will still be populated with all the changes to date. Nifty!

# When run with `pre-prepare`:
# * Determine current major version
# * Copy/move the changelog for current major version to CHANGELOG-TMP.md

# This needs to run before the @semantic-release/changelog `prepare` step
# @semantic-release/changelog will update CHANGELOG-TMP.md

# When run with `post-prepare`:
# * Determine current major version
# * Copy/move CHANGELOG-TMP.md to the changelog for current major version. i.e. `CHANGELOG-V2.md`

# When the @semantic-release/git `prepare` step then runs, it will commit all CHANGELOG* files.

# The pre-prepare step must be configured in your .releaserc.yml like so, BEFORE the @semantic-release/changelog plugin...
# - - "@semantic-release/exec"
#   - prepareCmd: "./scripts/semantic-release-prepare-changelog.sh pre-prepare ${nextRelease.version} ${nextRelease.channel}"

# The post-prepare step must be configured in your .releaserc.yml like so, AFTER the @semantic-release/changelog plugin and BEFORE the @semantic-release/git ...
# - - "@semantic-release/exec"
#     publishCmd: "./scripts/semantic-release-prepare-changelog.sh post-prepare ${nextRelease.version} ${nextRelease.channel}"

MODE="${1}"
NEW_VER="${2}"
CHANNEL="${3:-stable}"


NEW_MAJOR="$(cut -d '.' -f 1 <<< "${NEW_VER}")"

# TEMP_CHANGELOG_FILE="dist/CHANGELOG-TMP.md"
TEMP_CHANGELOG_FILE="CHANGELOG-TMP.md"
CHANGELOG_FILE="CHANGELOG-V${NEW_MAJOR}.md"
CHANNEL_CHANGELOG_FILE="CHANGELOG-V${NEW_MAJOR}-${CHANNEL}.md"


if [ "pre-prepare" == "${MODE}" ]; then
    echo "Preparing V${NEW_MAJOR} changelog file for the 'prepare' step of the update plugin "
    if [ -f "${CHANNEL_CHANGELOG_FILE}" ]; then
        mkdir -p "dist"
        mv "${CHANNEL_CHANGELOG_FILE}" "${TEMP_CHANGELOG_FILE}"
        # Delete changelog for other channels for current version
        # This should only happen after promoting to a higher channel.
        # Put this in some if logic to show a message that it's happening
        rm -f "CHANGELOG-V${NEW_MAJOR}-"*
    else
        echo "${CHANNEL_CHANGELOG_FILE} does not exist. A new changelog file will be created for V${NEW_MAJOR}in the ${CHANNEL} channel"
    fi
elif [ "post-prepare" == "${MODE}" ]; then
    echo "Preparing V${NEW_MAJOR} changelog file for 'prepare' step of the git plugin"
    # Ensure that the versioned changelog file is not there. It should have been MOVED by the prepare command above
    if [ -f "${CHANNEL_CHANGELOG_FILE}" ]; then
        echo "Error: ${CHANNEL_CHANGELOG_FILE} already exists but should not. Maybe the 'prepare' command was not called beforehand"
        exit 1
    fi
    if [ -f "${TEMP_CHANGELOG_FILE}" ]; then
        mv "${TEMP_CHANGELOG_FILE}" "${CHANNEL_CHANGELOG_FILE}"
        ls
        cp "${CHANNEL_CHANGELOG_FILE}" "${CHANGELOG_FILE}"
    else
        echo "Error: No changelog file (${TEMP_CHANGELOG_FILE}) was created by @semantic-release/changelog."
        exit 1
    fi
else
    echo "Mode must be 'prepare' or 'publish'"
    exit 1
fi
