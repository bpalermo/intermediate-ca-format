#!/usr/bin/env bash
# Copy the generated secret.pb.go over the committed one:
#   bazel run //intermediateca/v1:generate
# Arguments (from the BUILD file): the generated file, and where it goes
# relative to the workspace root.
set -euo pipefail

generated="$1"
destination="${BUILD_WORKSPACE_DIRECTORY:?run this with bazel run}/$2"

install -m 0644 "${generated}" "${destination}"
echo "wrote ${destination}"
