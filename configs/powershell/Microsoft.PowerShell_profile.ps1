$secretsDir = Join-Path $HOME ".secrets"
if (Test-Path $secretsDir) {
    foreach ($f in Get-ChildItem $secretsDir -Filter "*.env") {
        foreach ($line in Get-Content $f.FullName) {
            $line = $line.Trim()
            if ($line -eq "" -or $line.StartsWith("#")) { continue }
            $line = $line -replace "^export\s+", ""
            if ($line -match "^([^=]+)=(.*)$") {
                $name = $Matches[1]
                $raw = $Matches[2]
                if ($raw.StartsWith("'") -and $raw.EndsWith("'")) {
                    $val = $raw.Substring(1, $raw.Length - 2)
                } else {
                    $val = $raw.Trim('"')
                    $val = [regex]::Replace($val, '\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?', {
                        param($m)
                        $ref = [System.Environment]::GetEnvironmentVariable($m.Groups[1].Value, "Process")
                        if ($null -ne $ref) { $ref } else { $m.Value }
                    })
                }
                [System.Environment]::SetEnvironmentVariable($name, $val, "Process")
            }
        }
    }
}

oh-my-posh --init --shell pwsh --config ~/.config/powershell/jim.omp.json | Invoke-Expression
