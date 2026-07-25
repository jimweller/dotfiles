dock-restart()
{
  killall Dock
}

bluetooth-restart()
{
    sudo pkill bluetoothd
}

upgrade() {
  emulate -L zsh
  local -a _up_failed
  local _up_rc

  _up_run() {
    local label=$1; shift
    print -P "\n%F{cyan}==> ${label}%f"
    "$@"
    _up_rc=$?
    if (( _up_rc != 0 )); then
      print -P "%F{red}!! ${label} failed (exit ${_up_rc})%f"
      _up_failed+=("$label")
    fi
  }

  if (( $+commands[brew] )); then
    _up_run "brew update"           brew -v update
    _up_run "brew upgrade formulae" brew -v upgrade
    _up_run "brew upgrade casks"    brew upgrade --cask
    _up_run "brew cleanup"          brew -v cleanup --prune=5
    print -P "\n%F{cyan}==> brew doctor (informational)%f"
    brew doctor
  else
    print -P "%F{red}!! brew not found on PATH%f"
    _up_failed+=("brew missing")
  fi

  (( $+commands[mise] ))   && _up_run "mise tools"  mise upgrade
  (( $+commands[uv] ))     && _up_run "uv tools"    uv tool upgrade --all
  (( $+commands[npm] ))    && _up_run "npm globals" npm update -g
  (( $+commands[rustup] )) && _up_run "rustup"      rustup update

  if (( $+commands[claude] )); then
    _up_run "claude update"  claude update
    _up_run "claude plugins" claump
  fi
  (( $+commands[codex] )) && _up_run "codex update" codex update

  local _skills="$HOME/.config/dotfiles/scripts/ai-npx-skills.sh"
  [[ -x "$_skills" ]] && _up_run "ai skills (npx)" bash "$_skills"

  unfunction _up_run

  if (( ${#_up_failed} )); then
    print -P "\n%F{red}upgrade finished with ${#_up_failed} failure(s): ${(j:, :)_up_failed}%f"
    return 1
  fi
  print -P "\n%F{green}upgrade complete: all steps ok%f"
}
