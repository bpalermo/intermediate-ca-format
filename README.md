# intermediate-ca-format

The `intermediate-ca/v1` secret format: a small JSON document that holds an
intermediate CA (its certificate, its private key, the certificates up to a
trust anchor, and the trust anchor), a protobuf schema with
[protovalidate](https://github.com/bufbuild/protovalidate) rules, and a Go
package that reads and writes it with all the checks a reader needs.

A rotator writes the secret into a secret store; a certificate authority plugin
or a proxy reads it. They are separate programs, possibly in separate
languages and repositories, and this repository is what they agree on.

- [`docs/secret-format.md`](docs/secret-format.md): the specification.
- [`intermediateca/v1/secret.proto`](intermediateca/v1/secret.proto): the schema.
- [`testdata/`](testdata): documents any implementation must accept or refuse.
- Go package `github.com/bpalermo/intermediate-ca-format`.

## The document

```json
{
  "format": "intermediate-ca/v1",
  "cert": "-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----\n",
  "key": "-----BEGIN PRIVATE KEY-----\nMIGH...\n-----END PRIVATE KEY-----\n",
  "chain": "",
  "root": "-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----\n"
}
```

`cert` is the intermediate CA, `key` its PKCS#8 key, `chain` the certificates
between `cert` and `root` (empty when `root` issued `cert`), `root` the trust
anchor. A reader refuses an unknown `format`, a key that does not match, a
certificate that is not a CA, and one that does not verify to the root.

## Go

```go
import "github.com/bpalermo/intermediate-ca-format"

// Reading: parse and verify, as of now.
b, err := intermediateca.Decode(secretString)
switch {
case errors.Is(err, intermediateca.ErrExpired):
	// refresh the secret
case err != nil:
	// ErrInvalid, ErrKeyMismatch, ErrNotCA or ErrChain; never contains the key
	return err
}
b.Cert, b.Key, b.Chain, b.Root // *x509.Certificate, crypto.Signer, ...

// Pin the trust anchor.
if intermediateca.RootSHA256Hex(b) != wantRootSHA256 {
	return errors.New("unexpected root")
}

// Writing: the same bytes for the same certificates.
data, err := intermediateca.Encode(&intermediateca.Bundle{
	Cert: cert, Key: key, Chain: nil, Root: root,
})
```

`DecodeAt(data, t)` checks validity at `t` instead of now. The generated
message type (`Bundle.Raw`) is in
`github.com/bpalermo/intermediate-ca-format/intermediateca/v1`; its Go file is
committed, so `go get` needs no Bazel or `protoc`.

## Stability

Version 1 is frozen. A change that would alter what a v1 document means or
which documents are accepted is a new format, `intermediate-ca/v2` in package
`intermediateca/v2`, never an edit of v1; `buf breaking` against `main` enforces
this for the schema on every pull request, and the golden files in `testdata/`
for the rules. Go module versions are the repository's `v*` tags.

## Development

Bazel is the only build; see [AGENTS.md](AGENTS.md).

```bash
bazel test //...                          # unit tests, buf lint, generated code is fresh
bazel run //intermediateca/v1:generate    # after changing secret.proto
bazel run //:gazelle && bazel run //:format
```

## License

Apache-2.0.
