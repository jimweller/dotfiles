if (( ! $+commands[helm] )); then
  return
fi

alias h='helm'
alias hin='helm install'
alias hun='helm uninstall'
alias hse='helm search'
alias hup='helm upgrade'
