---
paths:
  - "**/*.cs"
  - "**/*.csproj"
  - "**/*.sln"
  - "**/Directory.Build.props"
---

# C# Development

## Toolchain

`dotnet` CLI only. Never use `msbuild`, `nuget.exe`, or IDE-generated build steps.

Pin the SDK with `global.json` at the repo root.

## Project Structure

```text
<solution-name>/
├── global.json
├── Directory.Build.props
├── <Solution>.sln
├── src/
│   └── <Project>/
│       ├── <Project>.csproj
│       └── ...
└── tests/
    └── <Project>.Tests/
        └── <Project>.Tests.csproj
```

Never put `.cs` files at the repo root. One project per directory.

## Directory.Build.props

Shared settings live here, not duplicated per csproj. Set `TargetFramework` to match the SDK pinned in `global.json`.

```xml
<Project>
  <PropertyGroup>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
```

Nullable reference types stay enabled. Never suppress with `#nullable disable`. Use `!` only when the invariant is proven locally.

## Testing

xUnit is the test framework. One test project per production project, named `<Project>.Tests`.

```bash
dotnet test
dotnet test --collect:"XPlat Code Coverage"
```

Use `NSubstitute` for mocks. Arrange-Act-Assert structure per test.

## Formatting and Lint

```bash
dotnet format          # apply
dotnet format --verify-no-changes   # CI check
```

Style rules live in `.editorconfig` at the repo root. Analyzer violations are build errors, not warnings.

## Style

- File-scoped namespaces: `namespace Foo.Bar;`
- `var` when the type is obvious from the right-hand side, explicit type otherwise
- `async`/`await` all the way down. Never `.Result` or `.Wait()`
- Suffix async methods with `Async`
- `record` for immutable data, `class` for behavior
- Constructor injection for dependencies. No service locator
- XML doc comments (`///`) on public library API only. Internal and private members need none

## New Project

```bash
dotnet new sln -n <Solution>
dotnet new classlib -o src/<Project>
dotnet new xunit -o tests/<Project>.Tests
dotnet sln add src/<Project> tests/<Project>.Tests
dotnet add tests/<Project>.Tests reference src/<Project>
```
