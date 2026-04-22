####################[ mise: polyglot tool version manager (https://mise.jdx.dev) ]####################
# Custom segment. p10k has no built-in mise segment; substitutes for the old asdf segment.
# Source: https://github.com/dagadbm/dotfiles/blob/master/zsh/p10k.mise.zsh (p10k issue #2212).
function prompt_mise() {
  local plugins=("${(@f)$(mise ls --local 2>/dev/null | awk '!/\(symlink\)/ && $3!="~/.tool-versions" && $3!="~/.config/mise/config.toml" {print $1, $2}')}")
  local plugin
  for plugin in ${(k)plugins}; do
    local parts=("${(@s/ /)plugin}")
    local tool=${(U)parts[1]}
    local version=${parts[2]}
    local icon_var="POWERLEVEL9K_${tool}_ICON"
    local expansion_var="POWERLEVEL9K_MISE_${tool}_VISUAL_IDENTIFIER_EXPANSION"
    if [[ -n "${(P)icon_var}" ]] || [[ -n "${icons[${tool}_ICON]}" ]] || [[ -n "${(P)expansion_var}" ]]; then
      p10k segment -r -i "${tool}_ICON" -s $tool -t "$version"
    fi
  done
}

# Direnv-style indicator: fires when any mise config file exists in cwd ancestry.
# Shows count of env vars mise would apply for this project.
function prompt_mise_env() {
  local dir=$PWD
  while [[ -n $dir && $dir != / ]]; do
    if [[ -f $dir/mise.toml || -f $dir/.mise.toml || -f $dir/mise/config.toml || -f $dir/.mise/config.toml || -f $dir/.tool-versions ]]; then
      local count=$(mise env --shell bash 2>/dev/null | grep -cE '^export [A-Z_][A-Z_0-9]*=')
      p10k segment -r -t $'\ue691'"{${count:-0}}"
      return
    fi
    dir=${dir:h}
  done
}
typeset -g POWERLEVEL9K_MISE_ENV_FOREGROUND=178

# State names come from mise's tool names (e.g. `node`, `go`), uppercased.
# These differ from asdf plugin names (`nodejs`, `golang`, `dotnet-core`).
typeset -g POWERLEVEL9K_MISE_FOREGROUND=66
typeset -g POWERLEVEL9K_MISE_RUBY_FOREGROUND=168
typeset -g POWERLEVEL9K_MISE_PYTHON_FOREGROUND=37
typeset -g POWERLEVEL9K_MISE_GO_FOREGROUND=37
typeset -g POWERLEVEL9K_MISE_NODE_FOREGROUND=70
typeset -g POWERLEVEL9K_MISE_RUST_FOREGROUND=37
typeset -g POWERLEVEL9K_MISE_DOTNET_FOREGROUND=134
typeset -g POWERLEVEL9K_MISE_FLUTTER_FOREGROUND=38
typeset -g POWERLEVEL9K_MISE_LUA_FOREGROUND=32
typeset -g POWERLEVEL9K_MISE_JAVA_FOREGROUND=32
typeset -g POWERLEVEL9K_MISE_PERL_FOREGROUND=67
typeset -g POWERLEVEL9K_MISE_ERLANG_FOREGROUND=125
typeset -g POWERLEVEL9K_MISE_ELIXIR_FOREGROUND=129
typeset -g POWERLEVEL9K_MISE_POSTGRES_FOREGROUND=31
typeset -g POWERLEVEL9K_MISE_PHP_FOREGROUND=99
typeset -g POWERLEVEL9K_MISE_HASKELL_FOREGROUND=172
typeset -g POWERLEVEL9K_MISE_JULIA_FOREGROUND=70
# IaC tools — terraform uses p10k built-in TERRAFORM_ICON; opentofu/terragrunt
# reuse the glyphs already defined for the tofu_version/terragrunt_version custom segments.
typeset -g POWERLEVEL9K_MISE_TERRAFORM_FOREGROUND=57
typeset -g POWERLEVEL9K_MISE_TERRAFORM_VISUAL_IDENTIFIER_EXPANSION=$'\ue8bd'
typeset -g POWERLEVEL9K_MISE_OPENTOFU_FOREGROUND=220
typeset -g POWERLEVEL9K_MISE_OPENTOFU_VISUAL_IDENTIFIER_EXPANSION=$'\ue21a'
typeset -g POWERLEVEL9K_MISE_TERRAGRUNT_FOREGROUND=214
typeset -g POWERLEVEL9K_MISE_TERRAGRUNT_VISUAL_IDENTIFIER_EXPANSION=$'\U000f096f'
