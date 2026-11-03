# dotfiles

Lets T3 Code add an Asana devbox as an SSH environment.

T3 Code starts its remote server with `sh -l -s`. On devboxes, `/etc/profile` loads bash-only
files, so `sh` (dash) exits before T3's script runs. `.config/zsh/t3-ssh.zsh` runs that one
command in `bash -l` instead and leaves every other command alone. `install.sh` links it and
loads it from `~/.zshenv`, the only startup file zsh reads for commands run over SSH. It also sets
the devbox's pretty hostname to its Coder workspace name, which T3 Code shows as the environment
name (otherwise every devbox is `sand000`).

Inside the devbox:

```sh
coder dotfiles https://github.com/dyurinov/dotfiles.git
```

`bin/devboxes` (run on the Mac) creates or starts `dyurinov-1`, `dyurinov-2` and `dyurinov-3`
with these dotfiles and checks the fix is installed on each.

Then add the devbox in T3 Code under **Settings → Environments → Add environment → SSH**
as `coder.<workspace>`.
