# Forked from ohmyzsh/plugins/common-aliases.
# Undesirables commented out with reason; uncomment to re-enable.

# ── ls shortcuts ──────────────────────────────────────────────────────────────
# Disabled: collide with zsh-eza-ls-plugin (l, la, ll, lt, tree).
# alias l='ls -lFh'
# alias la='ls -lAFh'
# alias lr='ls -tRFh'
# alias lt='ls -ltFh'
# alias ll='ls -l'
alias ldot='ls -ld .*'
# alias lS='ls -1FSsh'
# alias lart='ls -1Fcart'
# alias lrt='ls -1Fcrt'
# alias lsr='ls -lARFh'
# alias lsn='ls -1'

# Disabled: shadows zsh file named zshrc; zsh already has `edit-command-line`.
# alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

alias t='tail -f'

# ── Global pipe aliases ───────────────────────────────────────────────────────
# Disabled: silent mid-line rewrites (e.g. `echo H` becomes `echo | head`).
# alias -g H='| head'
# alias -g T='| tail'
# alias -g G='| grep'
# alias -g L="| less"
# alias -g M="| most"
# alias -g LL="2>&1 | less"
# alias -g CA="2>&1 | cat -A"
# alias -g NE="2> /dev/null"
# alias -g NUL="> /dev/null 2>&1"
# alias -g P="2>&1| pygmentize -l pytb"

alias dud='du -d 1 -h'
(( $+commands[duf] )) || alias duf='du -sh *'
(( $+commands[fd] )) || alias fd='find . -type d -name'
alias ff='find . -type f -name'

alias h='history'
# Disabled: hgrep rarely used.
# alias hgrep="fc -El 0 | grep"
# Disabled: shadows zsh's run-help.
# alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'

# ── Interactive safety trio ───────────────────────────────────────────────────
# Disabled: safe-rm handles rm (alias and $PATH both point to shell-safe-rm).
# alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ── Suffix aliases ────────────────────────────────────────────────────────────
# Disabled entire block: references tools that don't exist on macOS (acroread,
# xdvi, xchm, djview, unace); media block puts `rm` in mplayer suffix list,
# colliding with safe-rm; run-command-on-bare-filename behavior is surprising.
#
# autoload -Uz is-at-least
# if is-at-least 4.2.0; then
#   if [[ -n "$BROWSER" ]]; then
#     _browser_fts=(htm html de org net com at cx nl se dk)
#     for ft in $_browser_fts; do alias -s $ft='$BROWSER'; done
#   fi
#   _editor_fts=(cpp cxx cc c hh h inl asc txt TXT tex)
#   for ft in $_editor_fts; do alias -s $ft='$EDITOR'; done
#   if [[ -n "$XIVIEWER" ]]; then
#     _image_fts=(jpg jpeg png gif mng tiff tif xpm)
#     for ft in $_image_fts; do alias -s $ft='$XIVIEWER'; done
#   fi
#   _media_fts=(ape avi flv m4a mkv mov mp3 mpeg mpg ogg ogm rm wav webm)
#   for ft in $_media_fts; do alias -s $ft=mplayer; done
#   alias -s pdf=acroread
#   alias -s ps=gv
#   alias -s dvi=xdvi
#   alias -s chm=xchm
#   alias -s djvu=djview
#   alias -s zip="unzip -l"
#   alias -s rar="unrar l"
#   alias -s tar="tar tf"
#   alias -s tar.gz="echo "
#   alias -s ace="unace l"
# fi

# Disabled: belongs with completions, not aliases.
# zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'
