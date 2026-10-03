# dotfiles

Personal Linux devbox setup: custom Helix, native TypeScript server, tmux, and Git ignores.

Inside the devbox (both repositories are public):

```sh
coder dotfiles https://github.com/dyurinov/dotfiles.git
```

Repeat the command to pull updates. Coder runs `install.sh`, which builds the pinned
Helix fork and installs official native TypeScript from npm, then links configuration
and `~/.local/bin/{hx,tsgo}`. Versions are pinned in `versions.env`; completed
installations are reused. Requires Git, mise (or Rust 1.90+), Node 16.20+ with npm,
a C/C++ compiler, tmux, and zsh. The webapp devbox has these tools; mise installs
the pinned Rust toolchain when needed. No sudo.
Ensure `~/.local/bin` is on PATH (already configured on the webapp devbox).

- [Helix](https://github.com/dyurinov/helix): your editor changes, including Markdown
  reading mode, file explorer, and LSP tuning. Space+m toggles reading mode; Space+E
  opens the explorer. Clipboard uses tmux. Builds the 19 grammars listed in
  `languages.toml`; edit that list before the first build if you need more.
- [Official TypeScript](https://github.com/microsoft/TypeScript): stock 7.0.2 native
  compiler/LSP from npm. `tsgo` is a local alias for its `tsc` executable and accepts
  `--lsp --stdio`. Your private TypeScript fork is kept separate from this setup.
- tmux: Ctrl+b, red/yellow theme, vi copy mode, SSH clipboard support, no plugins.

Tools live in `~/.local/share/devbox-tools/<tool>/<commit-or-version>/`; Helix's
source/build cache lives in `~/.cache/devbox-dotfiles/`. To update, change the
Helix commit or TypeScript version in `versions.env`, push, and run Coder again.
Old builds remain available for rollback. Optional
language tools are `uv` with project-accessible Pyright/Ruff, and `taplo`.

Existing paths are moved to `~/.local/state/devbox-dotfiles/backups/<timestamp>-<pid>/`
before linking. Correct links are unchanged on reruns; live tmux is reloaded.
Restore by removing the new link and moving its backup back. Git identity,
authentication, signing, and shell startup files are preserved. Git automatically
uses `.config/git/ignore` unless `core.excludesFile` overrides it.

Preview with `./install.sh --dry-run`. Test configuration without tool builds:

```sh
DOTFILES_TARGET=/tmp/dotfiles-test DOTFILES_SKIP_TOOLS=1 ./install.sh
```

Normal installation refuses macOS, protecting the laptop's Ctrl+g tmux setup.
