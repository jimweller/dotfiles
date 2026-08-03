---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust Development

## Toolchain

`cargo` only, from a rustup-managed toolchain. Never invoke `rustc` directly. A Homebrew `rust` install ignores `rust-toolchain.toml`, so the rustup toolchain must come first on PATH.

Pin the toolchain with `rust-toolchain.toml` at the repo root:

```toml
[toolchain]
channel = "1.97"
components = ["rustfmt", "clippy"]
profile = "minimal"
```

Commit `Cargo.lock` for every crate, binary or library. `cargo new` tracks it by default.

## Project Structure

```text
<crate-name>/
├── Cargo.toml
├── Cargo.lock
├── rust-toolchain.toml
├── rustfmt.toml
├── src/
│   ├── lib.rs
│   ├── main.rs
│   └── <module>.rs
├── tests/
│   └── <feature>.rs
└── benches/
```

Unit tests live in the file they cover inside `#[cfg(test)] mod tests`. Integration tests live in `tests/`, one binary per file, and exercise only the public API.

Modules use `<module>.rs` beside a `<module>/` directory. Never `mod.rs`.

A workspace root has no `[package]` section, only `[workspace]` with `members` and `[workspace.dependencies]`.

## Cargo.toml Template

Set `edition` to the current edition and let `rust-version` match the channel in `rust-toolchain.toml`.

```toml
[package]
name = "<crate-name>"
version = "0.1.0"
edition = "2024"
rust-version = "1.97"

[dependencies]

[dev-dependencies]

[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
all = "deny"
pedantic = "warn"
```

Add dependencies with `cargo add` so the version constraint is resolved, never by hand-editing a version into the manifest.

## Testing

```bash
cargo test
cargo test --all-features
cargo test --doc
```

`mockall` generates trait mocks. Gate it behind `#[cfg_attr(test, automock)]` so production builds carry no mock code.

Doc examples in `///` comments are tests. Keep them compiling.

## Formatting and Lint

```bash
cargo fmt              # apply
cargo fmt --check      # CI check
cargo clippy --all-targets --all-features -- -D warnings
```

Default rustfmt style. `rustfmt.toml` exists only when a project needs an override. Clippy warnings are errors in CI.

## Async

`tokio` is the runtime. Never mix in `async-std` or `smol`.

- `#[tokio::main]` on the binary entry point, `#[tokio::test]` on async tests
- Never call `block_on` inside an async context
- Blocking work goes through `tokio::task::spawn_blocking`

## Style

- Libraries define error enums with `thiserror`. Binaries use `anyhow` at the top level
- Propagate with `?`. No `.unwrap()` or `.expect()` outside tests and `main`
- `unsafe` is forbidden by the manifest lint. Reach for a safe crate instead
- Borrow in function arguments: `&str` over `String`, `&[T]` over `Vec<T>`
- Derive `Debug` on every public type. Derive `Clone` only when the type is cheap to copy
- One `impl` block per trait

## New Project

```bash
cargo new <name>            # binary
cargo new --lib <name>      # library
cargo add --dev mockall
```
