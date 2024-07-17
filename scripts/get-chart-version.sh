#!/usr/bin/env bash

# Script to derive current Smile CDR Helm Chart version
# By default it outputs the full version from the Smile CDR Helm Chart's 'Chart.yaml' 'version:' field. e.g.:
# `1.0.0-pre.127`

# The below is not yet implemented
# Can also provide different version formats major, minor, patch and pre. e.g.:
# * Major `1`
# * Minor `1.0`
# * Patch `1.0.0`
# * Pre `1.0.0-pre`

# Usage:
# get-version.sh


grep "^version: " src/main/charts/smilecdr/Chart.yaml | sed -E 's/^version: (.*)$/\1/'
