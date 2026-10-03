# dotfiles

Personal Linux devbox setup: custom Helix, native TypeScript server, tmux, and Git ignores.

Inside the devbox, with Git credentials that can read all three private repositories:

```sh
coder dotfiles https://github.com/dyurinov/dotfiles.git
```

Repeat the command to pull updates. Coder runs `install.sh`, which builds the pinned
forks in `forks.env`, then links configuration and `~/.local/bin/{hx,tsgo}`. First
installation downloads dependencies and compiles; completed builds are reused.
Requires Git, Rust/rustup, Go, a C/C++ compiler, tmux, and zsh. The webapp devbox has
these build tools. Rust uses the fork's toolchain pin; Go uses 1.26.4. No sudo.
Ensure `~/.local/bin` is on PATH (already configured on the webapp devbox).

- [Helix](https://github.com/dyurinov/helix): your editor changes, including Markdown
  reading mode, file explorer, and LSP tuning. Space+m toggles reading mode; Space+E
  opens the explorer. Clipboard uses tmux. Builds the 19 grammars listed in
  `languages.toml`; edit that list before the first build if you need more.
- [TypeScript native](https://github.com/dyurinov/typescript-go): `helix-performance`
  preserves the development checkout. The pinned `devbox-release-37` branch contains
  the exact source archive used by your installed `7.0.2-helix.20260930.37`, rather
  than newer experiments. Linux binaries are built locally with the original PGO
  profile; Mac performance measurements do not establish Linux performance.
- tmux: Ctrl+b, red/yellow theme, vi copy mode, SSH clipboard support, no plugins.

Tools live in `~/.local/share/devbox-tools/<tool>/<commit>/`; source/build caches
live in `~/.cache/devbox-dotfiles/`. To update a tool, push its source and change
its commit in `forks.env`. Old builds remain available for rollback. Optional
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
