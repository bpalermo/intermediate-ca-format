module github.com/bpalermo/intermediate-ca-format

go 1.27.2

require (
	buf.build/gen/go/bufbuild/protovalidate/protocolbuffers/go v1.36.12-20260825204119-511051f7f437.1
	buf.build/go/protovalidate v1.4.0
	google.golang.org/protobuf v1.36.12
)

require (
	cel.dev/cel-go v0.32.0 // indirect
	cel.dev/expr v0.25.3 // indirect
	github.com/BurntSushi/toml v1.4.1-0.20240526193622-a339e1f7089c // indirect
	github.com/antlr4-go/antlr/v4 v4.13.1 // indirect
	github.com/uudashr/gocognit v1.2.2 // indirect
	go.yaml.in/yaml/v3 v3.0.5 // indirect
	golang.org/x/exp v0.0.0-20260820142414-ca536658362e // indirect
	golang.org/x/exp/typeparams v0.0.0-20231108232855-2478ac86f678 // indirect
	golang.org/x/mod v0.42.0 // indirect
	golang.org/x/sync v0.24.0 // indirect
	golang.org/x/text v0.41.0 // indirect
	golang.org/x/tools v0.52.0 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20260819154853-08b0e4226688 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260819154853-08b0e4226688 // indirect
	honnef.co/go/tools v0.8.2 // indirect
)

tool (
	github.com/uudashr/gocognit/cmd/gocognit
	honnef.co/go/tools/cmd/staticcheck
)
