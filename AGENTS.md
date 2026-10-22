# AGENTS.md

Guidance for agents working in this repository.

## What this is

The `intermediate-ca/v1` secret format: a JSON document holding an
intermediate CA (certificate, PKCS#8 key, chain, root), its protobuf schema
with protovalidate rules, and the Go package `intermediateca` that reads and
writes it. It is a library for programs in other repositories (a rotator that
writes the secret, plugins that read it); it builds no binary and no image.
The repository is a public one: no account IDs, ARNs, key IDs, personal
domains or host names anywhere (code, tests, testdata, docs, workflows).
Examples use `example.org`. The keys in `testdata/` are derived from public
labels and protect nothing.

`docs/secret-format.md` is the specification and is authoritative; the proto
and the Go code follow it. **Version 1 is frozen**: nothing in the schema is
renamed, renumbered, retyped or removed, and no rule changes what is accepted.
A change that needs one of those is `intermediate-ca/v2` in a new package
`intermediateca/v2`. `buf breaking` enforces it for the schema and the golden
files in `testdata/` for the rules.

## Build and test

```bash
bazel test //...                          # unit tests, buf lint, generated code is fresh
bazel run //:gazelle                      # after adding, removing or renaming any .go file
bazel run //:format                       # Starlark, Go, shell and proto; CI runs //:format.check
bazel mod tidy                            # after changing go.mod or a bazel_dep
bazel build --config=ci //...             # what CI builds: lockfile must be current, shellcheck and gocognit on
scripts/proto-breaking.sh                 # buf breaking against origin/main
bazel run //intermediateca/v1:generate    # regenerate secret.pb.go after editing secret.proto
bazel run //internal/gentestdata          # regenerate testdata/ after adding or changing a case
```

Bazel is the only build. Never use the host `go` tool, and do not "fix" go.mod
with `go mod tidy`. Change a Go dependency through rules_go's SDK:

```bash
bazel run @rules_go//go -- get github.com/some/module@v1.2.3
```

Follow it with `bazel mod tidy` and `bazel run //:gazelle`. User-local Bazel
settings go in `user.bazelrc` (untracked); on a machine with `GOPROXY=direct`
it points module fetches at the public proxy.

Linting is part of the build. Every Go package is compiled with the analyzers
of `//:nogo` (`go vet`'s and staticcheck's), and a finding is a compile error:
fix it rather than excluding the file. Shell scripts are checked by shellcheck
and Go functions by gocognit, both aspects that `--config=ci` turns on; a
script is only seen through a Bazel target (`//bazel:scripts`,
`//scripts:scripts`). gocognit (`bazel/lint/linters.bzl`) fails a function over
15 and visits production code only; the threshold never goes up.

## Layout

Flat: no `cmd/`, no `pkg/`. Packages live at the root; `internal/` holds only
test helpers.

- `intermediateca.go` (root package, import path
  `github.com/bpalermo/intermediate-ca-format`): `Bundle`, `Decode`,
  `DecodeAt`, `Encode`, `RootSHA256`, `RootSHA256Hex` and the `Err*` sentinels.
  Errors never contain key material; keep it that way (the tests check).
- `intermediateca/v1`: `secret.proto` (buf's rule: directory = package) and
  the committed `secret.pb.go`.
- `testdata/`: golden documents and `manifest.json`, for every implementation.
- `docs/secret-format.md`: the specification.
- `internal/testpki` (test-only): certificate hierarchies, with fixed keys.
- `internal/gentestdata` (test-only): writes `testdata/`.
- `bazel/`: `workspace_status.sh` (version stamping, read by `release.yml`),
  `ci-impacted-targets.sh` (bazel-diff), `nogo/`, `lint/`, `format/`.
- `scripts/proto-breaking.sh`: the `buf breaking` check.

## Generated code

`intermediateca/v1/secret.pb.go` is committed so that `go get` works without
Bazel. `bazel run //intermediateca/v1:generate` writes it from `secret.proto`
(protoc and protoc-gen-go, as rules_go runs them), and
`//intermediateca/v1:generated_test` fails if the committed file differs. The
file is marked `linguist-generated` in `.gitattributes`, which also keeps the
formatter off it. Gazelle is told `proto disable` there: the BUILD file is
written by hand (`proto_library` for buf, the generator, the checks) and
Gazelle only generates the `go_library` of the committed file, which the root
`BUILD.bazel` resolves the package's import path to.

protovalidate's proto comes from the BCR module `protovalidate`; its Go
runtime and the generated `buf/validate` Go package come from go.mod. Keep the
`protovalidate` bazel_dep and `buf.build/go/protovalidate` in step. The
`gazelle_override` of `cel.dev/cel-go` regenerates its BUILD files, whose
`go_default_library` names Gazelle's resolution does not find.

## Versions and releasing

`VERSION` is the release being worked towards. A commit tagged `v<VERSION>`
(or `v<VERSION>-rc.<n>`) is that release; any other commit is a snapshot of it
(`bazel/workspace_status.sh`). The Go module version is the tag. Pushing a
`v*` tag on a commit of main runs `release.yml`, which checks the tag and
creates a GitHub Release with notes only. Do not push tags by hand unless
releasing.

## CI

`.github/workflows/ci.yml`: `lint` (format check, Gazelle staleness) always
runs; `diff` computes the impacted targets with bazel-diff
(`bazel/ci-impacted-targets.sh`) and `build` builds and tests only those, then
runs `scripts/proto-breaking.sh`. A change to anything outside the graph that
CI depends on (`.bazelrc`, `MODULE.bazel`, the lint `.bzl` files, the workflow,
the script) must be in the script's seed list, or CI would skip the build.
`ci` is the aggregate check to require. Actions are pinned to commit SHAs with
the version in a comment.

## Pull requests

One topic per pull request. Verify with `bazel build --config=ci //... &&
bazel test --config=ci //...` before pushing.
