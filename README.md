# dotfiles

Small personal configuration for Linux devboxes: Helix, tmux, and global Git ignores.

Run **inside the devbox** using Git credentials that can read this private repo:

```sh
coder dotfiles https://github.com/dyurinov/dotfiles.git
```

Run the same command again to pull updates and reapply the links. Coder executes
the executable `install.sh`. It installs configuration only, without sudo or
package downloads, and reloads an existing tmux server.

The installer symlinks `.config/helix`, `.config/git/ignore`, and `.tmux.conf`.
Existing files, directories, or symlinks are moved into
`~/.local/state/devbox-dotfiles/backups/<timestamp>-<pid>/` first. Reruns leave
correct links alone. To restore a backup, remove the corresponding new symlink
and move its saved path back. Back up the entire Helix directory when restoring it.

Preview changes with `./install.sh --dry-run`. For an isolated test:

```sh
DOTFILES_TARGET=/tmp/dotfiles-test ./install.sh
```

The installer refuses a normal install on macOS, protecting the laptop's Ctrl+g
tmux configuration. Devbox tmux uses Ctrl+b, your red/yellow theme, vi copy mode,
and SSH clipboard support. There are no tmux plugins.

Helix settings target standard Helix 25.07.1 or newer. Use it inside tmux for
clipboard integration. The Mac-only clipboard backend and absolute TypeScript
path are replaced by tmux and `tsgo` on PATH. Custom-fork Markdown reading,
file-explorer, and LSP tuning options are omitted; Space+E opens the stock file
picker. Your theme, relative numbers, indent guides, cursor shapes, and language
preferences are retained.

Install Helix separately. Optional language tools are `tsgo --lsp --stdio`,
`uv` with project-accessible Pyright/Ruff, and `taplo`.

Git uses `.config/git/ignore` automatically unless `core.excludesFile` overrides
it. Git identity, authentication, signing, and shell startup files are preserved.
