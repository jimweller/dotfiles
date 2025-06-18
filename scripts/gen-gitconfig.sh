#!/bin/bash
CONFIG="$HOME/.gitconfig-static"

git config --file "$CONFIG" commit.gpgsign true
git config --file "$CONFIG" gpg.format ssh
git config --file "$CONFIG" gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"

git config --file "$CONFIG" core.editor "code --wait"
git config --file "$CONFIG" core.whitespace "fix,-indent-with-non-tab,trailing-space,cr-at-eol"
git config --file "$CONFIG" core.pager ""

git config --file "$CONFIG" mergetool.vscodeM.cmd "code --wait \$MERGED"
git config --file "$CONFIG" merge.tool vscodeM

git config --file "$CONFIG" difftool.vscodeD.cmd "code --wait --diff \$LOCAL \$REMOTE"
git config --file "$CONFIG" diff.tool vscodeD

git config --file "$CONFIG" init.defaultBranch main
git config --file "$CONFIG" rerere.enabled true

git config --file "$CONFIG" user.useConfigOnly true

git config --file "$CONFIG" pager.branch false

git config --file "$CONFIG" filter.lfs.clean "git-lfs clean -- %f"
git config --file "$CONFIG" filter.lfs.smudge "git-lfs smudge -- %f"
git config --file "$CONFIG" filter.lfs.process "git-lfs filter-process"
git config --file "$CONFIG" filter.lfs.required true

# git config --file "$CONFIG" credential.helper "store --file=$HOME/.git-credentials-personal"
# git config --file "$CONFIG" credential."https://github.com".username jimweller
