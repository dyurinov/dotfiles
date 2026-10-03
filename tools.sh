#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
# Sourced by install.sh; its backup/link functions also handle the executables.
: "${repo_dir:?}" "${target_dir:?}" "${dry_run:?}"
# shellcheck source=forks.env
source "$repo_dir/forks.env"

fetch_source() {
    local repository="$1" revision="$2" source_dir="$3"
    if [ -d "$source_dir/.git" ] &&
        [ "$(git -C "$source_dir" rev-parse HEAD)" = "$revision" ]; then
        return
    fi
    mkdir -p -- "$source_dir"
    git init --quiet "$source_dir"
    if ! git -C "$source_dir" remote get-url origin >/dev/null 2>&1; then
        git -C "$source_dir" remote add origin "$repository"
    fi
    GIT_TERMINAL_PROMPT=0 git -C "$source_dir" fetch --quiet --depth=1 origin "$revision"
    git -C "$source_dir" checkout --quiet --detach "$revision"
}

install_tools() {
    local tools_dir="$target_dir/.local/share/devbox-tools"
    local cache_dir="$target_dir/.cache/devbox-dotfiles"
    local helix_dir="$tools_dir/helix/$HELIX_REV"
    local tsgo_dir="$tools_dir/tsgo/$TSGO_REV"
    local dependency source_dir

    if "$dry_run"; then
        printf 'Would build/reuse Helix %s and tsgo %s (%s).\n' "$HELIX_REV" "$TSGO_VERSION" "$TSGO_REV"
    else
        if [ "$(uname -s)" != Linux ]; then
            printf 'Tool builds require Linux. Use DOTFILES_SKIP_TOOLS=1 for config-only tests.\n' >&2
            exit 1
        fi
        for dependency in git cargo go cc c++; do
            if ! command -v "$dependency" >/dev/null 2>&1; then
                printf 'Missing build dependency: %s\n' "$dependency" >&2
                exit 1
            fi
        done

        if [ ! -f "$tsgo_dir/.complete" ]; then
            printf 'Building tsgo %s from %s\n' "$TSGO_VERSION" "$TSGO_REV"
            source_dir="$cache_dir/tsgo-$TSGO_REV"
            fetch_source "$TSGO_REPO" "$TSGO_REV" "$source_dir"
            mkdir -p -- "$tsgo_dir/bin"
            bash "$source_dir/helix-local/build.sh" "$TSGO_VERSION" "$tsgo_dir/bin/tsgo"
            touch "$tsgo_dir/.complete"
        fi

        if [ ! -f "$helix_dir/.complete" ]; then
            printf 'Building Helix from %s\n' "$HELIX_REV"
            source_dir="$cache_dir/helix-$HELIX_REV"
            fetch_source "$HELIX_REPO" "$HELIX_REV" "$source_dir"
            mkdir -p -- "$helix_dir/bin" "$helix_dir/runtime"
            (
                cd -- "$source_dir"
                # Build with the installed Rust toolchain and our grammar selection.
                HELIX_DEFAULT_RUNTIME="$helix_dir/runtime" XDG_CONFIG_HOME="$repo_dir/.config" \
                    cargo build --release --locked -p helix-term --jobs "${DOTFILES_BUILD_JOBS:-4}"
            )
            cp -- "$source_dir/target/release/hx" "$helix_dir/bin/hx"
            cp -R -- "$source_dir/runtime/themes" "$source_dir/runtime/queries" "$helix_dir/runtime/"
            mkdir -p -- "$helix_dir/runtime/grammars"
            find "$source_dir/runtime/grammars" -maxdepth 1 -type f -name '*.so' \
                -exec cp -- '{}' "$helix_dir/runtime/grammars/" \;
            "$helix_dir/bin/hx" --version
            touch "$helix_dir/.complete"
        fi
    fi

    install_link .local/bin/hx "$helix_dir/bin/hx"
    install_link .local/bin/tsgo "$tsgo_dir/bin/tsgo"
}
