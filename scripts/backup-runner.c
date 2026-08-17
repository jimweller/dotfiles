/* TCC identity carrier for the scheduled backup.
 *
 * launchd must run this binary instead of sync.sh directly. macOS attributes
 * access to a FileProvider domain under ~/Library/CloudStorage to the
 * responsible process, and for a #!/bin/zsh script that process is /bin/zsh.
 * /bin/zsh is an Apple platform binary, so tccd refuses to prompt for it
 * ("Platform binary prompting is 'Deny'") and every read inside the Google
 * Drive or OneDrive domain fails with EPERM. This binary is not a platform
 * binary, so it gets its own TCC identity, macOS prompts once per cloud
 * domain, and the approval persists.
 *
 * Build (done by install.macos.yaml):
 *   clang -O2 -DSYNC_SCRIPT='"/abs/path/scripts/sync.sh"' \
 *     -o ~/bin/dotfiles-backup-runner scripts/backup-runner.c
 *
 * The grant is keyed to this binary's path and code hash. Rebuilding it voids
 * the approvals and macOS prompts again on the next interactive run. Do not
 * re-sign it with `codesign -s -`; the linker's ad-hoc signature is what runs.
 * The script path is fixed at compile time on purpose, so the granted identity
 * cannot be reused to run something else.
 */
#include <stdio.h>
#include <unistd.h>

#ifndef SYNC_SCRIPT
#error "define SYNC_SCRIPT with the absolute path to sync.sh"
#endif

int main(void) {
    char *const args[] = {"/bin/zsh", SYNC_SCRIPT, NULL};
    execv("/bin/zsh", args);
    perror("execv /bin/zsh");
    return 1;
}
