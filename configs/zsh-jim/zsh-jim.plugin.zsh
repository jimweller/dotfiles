0=${(%):-%N}
source ${0:A:h}/00-secrets.zsh
source ${0:A:h}/03-path.zsh
source ${0:A:h}/05-quality-of-life.zsh
source ${0:A:h}/10-tmux.zsh
source ${0:A:h}/15-gpg.zsh
source ${0:A:h}/20-git.zsh
source ${0:A:h}/30-iac.zsh
source ${0:A:h}/40-aws.zsh
source ${0:A:h}/45-azure.zsh
source ${0:A:h}/50-ado.zsh
source ${0:A:h}/55-docker.zsh
source ${0:A:h}/60-k8s.zsh
source ${0:A:h}/70-ai.zsh
[[ "$(uname)" == "Darwin" ]] && source ${0:A:h}/90-macos.zsh
[[ "$(uname)" == "Linux" ]] && source ${0:A:h}/95-linux.zsh
