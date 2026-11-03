#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

if [ "$(uname -s)" != Linux ] && [ -z "${DOTFILES_TARGET:-}" ]; then
    printf 'Run this inside your Linux devbox. Use DOTFILES_TARGET for a test directory.\n' >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target_dir="${DOTFILES_TARGET:-$HOME}"

mkdir -p -- "$target_dir/.config/zsh"
ln -sfn -- "$repo_dir/.config/zsh/t3-ssh.zsh" "$target_dir/.config/zsh/t3-ssh.zsh"

# Commands run over SSH go through `zsh -c`, which reads .zshenv but not .zshrc.
zshenv_path="$target_dir/.zshenv"
# Expand HOME when zsh starts, not during installation.
# shellcheck disable=SC2016
hook_source='[[ -r "$HOME/.config/zsh/t3-ssh.zsh" ]] && source "$HOME/.config/zsh/t3-ssh.zsh"'
if ! grep -Fxqs -- "$hook_source" "$zshenv_path"; then
    printf '\n# T3 Code SSH launcher fix.\n%s\n' "$hook_source" >>"$zshenv_path"
fi
printf 'Installed T3 Code SSH launcher fix.\n'

# T3 Code names the environment after the pretty hostname, which is sand000 on every devbox.
if [ -z "${DOTFILES_TARGET:-}" ] && [ -n "${CODER_WORKSPACE_NAME:-}" ] && sudo -n true 2>/dev/null; then
    sudo -n hostnamectl set-hostname --pretty "$CODER_WORKSPACE_NAME"
    printf 'Named this devbox %s.\n' "$CODER_WORKSPACE_NAME"
fi
