#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

case "${1:-}" in
    '') dry_run=false ;;
    --dry-run) dry_run=true ;;
    *) printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    printf 'Usage: %s [--dry-run]\n' "$0" >&2
    exit 2
fi

# These settings belong on Linux; never replace the Mac's tmux config by accident.
if [ "$(uname -s)" != Linux ] && [ -z "${DOTFILES_TARGET:-}" ]; then
    printf 'Run this inside your Linux devbox. Use DOTFILES_TARGET for a test directory.\n' >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target_dir="${DOTFILES_TARGET:-$HOME}"
case "$target_dir" in
    /*) ;;
    *) printf 'DOTFILES_TARGET must be an absolute path.\n' >&2; exit 2 ;;
esac
backup_dir="$target_dir/.local/state/devbox-dotfiles/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"

install_link() {
    local relative_path="$1"
    local source_path="${2:-$repo_dir/$relative_path}"
    local target_path="$target_dir/$relative_path"

    if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
        printf 'Already installed: %s\n' "$relative_path"
        return
    fi
    if "$dry_run"; then
        printf 'Would link %s -> %s (backing up any existing path).\n' "$target_path" "$source_path"
        return
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        mkdir -p -- "$(dirname -- "$backup_dir/$relative_path")"
        mv -- "$target_path" "$backup_dir/$relative_path"
        printf 'Backup: %s\n' "$backup_dir/$relative_path"
    fi
    mkdir -p -- "$(dirname -- "$target_path")"
    ln -s -- "$source_path" "$target_path"
    printf 'Installed: %s\n' "$relative_path"
}

# Build before switching configuration to settings that require the custom editor.
if [ "${DOTFILES_SKIP_TOOLS:-0}" != 1 ]; then
    # shellcheck source=tools.sh
    source "$repo_dir/tools.sh"
    install_tools
fi

install_link .config/helix
install_link .config/git/ignore
install_link .tmux.conf

if ! "$dry_run" && [ -z "${DOTFILES_TARGET:-}" ] && command -v tmux >/dev/null 2>&1; then
    if tmux list-sessions >/dev/null 2>&1; then
        tmux source-file "$target_dir/.tmux.conf"
        printf 'Reloaded tmux; remote prefix is Ctrl+b.\n'
    fi
fi
