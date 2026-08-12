---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---

# PowerShell Conventions

## Runtime

Cross-platform PowerShell (`pwsh`) only. Never target Windows PowerShell or `powershell.exe`.

Scripts run unmodified on Windows, macOS, and Linux. Avoid platform-locked cmdlets such as `Get-WmiObject`, `Get-CimInstance`, and the registry provider. Avoid COM objects and `Add-Type` against Windows-only assemblies.

Branch on `$IsWindows`, `$IsMacOS`, or `$IsLinux` when platform behavior differs. Never branch on `$env:OS` or `[Environment]::OSVersion`.

Use `[System.IO.Path]::DirectorySeparatorChar` and `Join-Path` rather than literal separators. Read paths from `$env:HOME` and `$env:USERPROFILE` through `[Environment]::GetFolderPath()` instead of hardcoding either.

Prefer `$PSStyle` and cmdlet output over ANSI escape codes or console APIs.

## Script Preamble

Every script starts with:

```powershell
#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

Never omit strict mode. Never leave `$ErrorActionPreference` at the default.

## Finding Project Root

```powershell
$ProjectRoot = git rev-parse --show-toplevel
```

Script-relative when not in a git repo:

```powershell
$ProjectRoot = Split-Path -Parent $PSCommandPath
```

Never use `$PSScriptRoot` inside a function that may be dot-sourced.

## Functions

```powershell
function Get-Thing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [switch]$Force
    )

    ...
}
```

- Approved verbs only. Check with `Get-Verb`
- PascalCase for function and parameter names
- `[CmdletBinding()]` on every function
- Type-annotate all parameters
- Use `[switch]` for booleans, never `[bool]$Flag = $true`

## Module Layout

```text
<ModuleName>/
├── <ModuleName>.psd1
├── <ModuleName>.psm1
├── Public/
│   └── Get-Thing.ps1
├── Private/
│   └── Resolve-Internal.ps1
└── tests/
    └── Get-Thing.Tests.ps1
```

Export only `Public/` functions via `FunctionsToExport` in the manifest. Never `Export-ModuleMember -Function *`.

## Testing

Pester is the test framework. Test files are named `<Subject>.Tests.ps1`.

```powershell
Invoke-Pester -Path tests -Output Detailed
```

Use `Describe` / `Context` / `It` blocks. Mock with `Mock` inside the `Describe` scope.

## Linting

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

PSScriptAnalyzer findings are errors, not suggestions. Settings live in `PSScriptAnalyzerSettings.psd1` at the repo root.

## Style

- Full cmdlet names. Never aliases such as `ls`, `%`, `?`, `gci` in scripts
- Named parameters. Never positional binding in scripts
- Single quotes for literal strings, double quotes only when interpolating
- Output objects, not formatted text. Never `Write-Host` for data. Use `Write-Output` for data and `Write-Verbose` for diagnostics
- Use `Join-Path` for paths. Never string-concatenate with `/` or `\`
- Comment-based help (`.SYNOPSIS`, `.PARAMETER`) on exported module functions, since `Get-Help` reads it. Private helpers need none
