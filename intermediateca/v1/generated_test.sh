#!/usr/bin/env bash
# Fail if the committed secret.pb.go is not what secret.proto generates.
# Arguments (from the BUILD file): the generated file, the committed one.
set -euo pipefail

generated="$1"
committed="$2"

if ! diff -u "${committed}" "${generated}"; then
	echo "secret.pb.go is stale; run 'bazel run //intermediateca/v1:generate'" >&2
	exit 1
fi
echo "secret.pb.go is up to date"
