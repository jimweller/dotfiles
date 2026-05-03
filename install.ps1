$ErrorActionPreference = "Stop"

$CONFIG = "install.windows.yaml"
$DOTBOT_DIR = "submodules/dotbot"
$DOTBOT_BIN = "bin/dotbot"
$BASEDIR = $PSScriptRoot

Set-Location $BASEDIR
git -C $DOTBOT_DIR submodule sync --quiet --recursive
git submodule update --init --recursive $DOTBOT_DIR

foreach ($candidate in @('python', 'python3')) {
    try {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $ver = & $candidate -V 2>&1
        $ErrorActionPreference = $prev
        if ($ver -match 'Python 3') {
            $dotbotPath = Join-Path $BASEDIR $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN
            & $candidate $dotbotPath -d $BASEDIR -c $CONFIG @Args
            return
        }
    } catch {
        $ErrorActionPreference = "Stop"
    }
}
Write-Error "Python 3 not found."
