# Go Development

Apply when working with .go, go.mod, or go.sum files.

## Toolchain

`go` CLI only, modules only. Never use GOPATH mode, `dep`, or `vendor/` unless the repo already vendors.

Pin the language version with the `go` directive in `go.mod`. Every module in one repo carries the same version.

Third-party tool binaries are declared with `go get -tool` and run with `go tool <name>`. Never `go install` a tool globally to satisfy a project dependency. Generators that live in the repo run through `go run ./cmd/<generator>`, wired up with `//go:generate go run ./cmd/<generator>`.

## Module Path

The module path is the import path other code uses to reach the module. Use the resolvable VCS path, `github.com/<org>/<repo>`, whenever anything outside the repo imports it.

A non-URL path such as `org/team/service` compiles fine, but `go get` can never resolve it and every consumer needs a permanent `replace` directive. Choose one only for modules that stay inside a single workspace.

## Project Structure

Single module:

```text
<module-name>/
├── go.mod
├── go.sum
├── .golangci.yml
├── cmd/
│   └── <binary>/
│       └── main.go
├── internal/
│   └── <package>/
│       ├── <file>.go
│       └── <file>_test.go
└── testdata/
```

Multi-module workspace:

```text
<repo>/
├── go.work
├── <module-a>/
│   └── go.mod
└── <module-b>/
    └── go.mod
```

`go.work` lists every member. Sibling modules are joined with `replace <module> => ../<dir>`.

Everything not meant for external import goes in `internal/`. Never create a `pkg/` directory.

`main` packages hold wiring only. A `main` package that accumulates handlers, stores, and clients loses the ability to test any of it behind an interface, and coverage stalls at whatever the process-level tests reach.

## Test Layout

Go tests are co-located with the code they cover as `<file>_test.go`. A top-level `tests/` tree is for cross-language harnesses such as Playwright specs or bats suites, never for Go unit tests.

Tests that need live infrastructure carry a build tag:

```go
//go:build integration
```

Run them with `go test -tags integration ./...`. Ephemeral dependencies come from `testcontainers-go` rather than a shared environment.

## go.mod Template

```text
module github.com/<org>/<repo>

go 1.26
```

Add `tool` lines only for third-party generators.

## Testing

Standard library `testing` for structure, table-driven with `t.Run` subtests. `stretchr/testify` for assertions, `require` when the test must stop and `assert` when it continues. Use one assertion style per package instead of mixing testify with raw `t.Errorf`.

`testify/mock` is the mock library. Hand-written doubles are fine while the count stays small. Move to `mockery` with a `.mockery.yml` once maintaining them by hand becomes the bottleneck, and never mix generated and hand-written mocks for the same interface.

```bash
go test ./...
go test -race ./...
go test -cover ./...
go test -tags integration ./...
```

`-race` is mandatory for any package that starts a goroutine.

## Interfaces

Interfaces are declared in the consuming package and scoped to the methods that consumer calls. The implementing package returns a concrete type.

Accept interfaces, return concrete types. An interface past roughly ten methods is a split candidate.

## Errors

- Wrap with `fmt.Errorf("doing thing: %w", err)`. Never discard an error with `_`
- Conditions the caller branches on are sentinel errors, declared beside the interface they belong to and matched with `errors.Is`
- Typed errors are matched with `errors.As`. Never match on `.Error()` strings

```go
var ErrNotFound = errors.New("not found")
```

## Logging

`log/slog` only. Never `log.Printf`, `log.Fatalf`, or `fmt.Println` outside a generator `main`.

```go
slog.Error("create record", "record", name, "error", err)
```

Messages are lowercase with no format verbs. Keys are bare strings. Error paths log at error or warn before returning. Level comes from an env var or flag and defaults to a quiet level in production.

## Formatting and Lint

golangci-lint v2. The config file carries `version: "2"` at the top level.

```bash
golangci-lint run     # lint
golangci-lint fmt     # format
```

```yaml
version: "2"
linters:
  default: standard
  enable:
    - bodyclose
    - errorlint
    - revive
formatters:
  enable:
    - gofmt
    - goimports
```

Lint failures are build failures. `//nolint` requires a reason on the same line.

## Style

- `context.Context` is the first parameter and never stored in a struct. Test helpers take `t *testing.T` first
- Exported identifiers in library packages carry a doc comment that starts with the identifier name. `package main` symbols need one only when the comment says something the name does not
- No `panic` in library code. Panic only when a startup invariant fails
- Zero values are usable where practical. Prefer `var x []T` over `x := []T{}`

## New Project

```bash
mkdir -p <name>/cmd/<name> && cd <name>
go mod init github.com/<org>/<name>
go get github.com/stretchr/testify
go mod tidy
```
