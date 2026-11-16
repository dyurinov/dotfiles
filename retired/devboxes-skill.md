---
name: devboxes
description: Maintain Dmytro's Coder devboxes dyurinov-1/2/3 (T3 Code environments) — bring them up, update the template, check health, run the build watcher, update the T3 server, check Claude/Codex logins, fix T3 environment links. Use when the user says /devboxes, "check my devboxes", "update devboxes", "devbox loop/watcher", or reports a devbox/T3 environment problem.
---

# Devboxes

Three Coder workspaces, `dyurinov-1`, `dyurinov-2`, `dyurinov-3` (template `webapp`, region eu-central-1), each a T3 Code SSH environment. Your setup lives in the dotfiles repo `~/dev/devbox` (GitHub `dyurinov/dotfiles`, cloned on each box at `~/.config/coderv2/dotfiles`).

| Script (in `~/dev/devbox/bin`) | Does |
|---|---|
| `devboxes` (alias in `~/.zshrc`) | Creates missing boxes, starts stopped ones, checks the T3 SSH fix, checks Claude/Codex logins, then runs `devbox-forwards` |
| `devbox-forwards` | Fixed loopback ports for T3 links: `127.0.0.1:13771/13772/13773` → each box's T3 server `:3773`. Also runs on a box |
| `devbox-t3-update [names…]` | Installs the Mac T3 app's version on each box (`~/.t3/runtime/versions/<v>`) |
| `install.sh` (dotfiles) | On each box: T3 SSH launcher fix (`~/.config/zsh/t3-ssh.zsh` from `~/.zshenv`), pretty hostname = workspace name |

## Running commands from Claude Code

- **Every `coder`, `ssh coder.*`, `z devbox` call needs `dangerouslyDisableSandbox: true`**: the sandbox blocks Coder's tunnel.
- **Strip the SSH noise**: pipe output through `grep -v -i "startup script\|troubleshooting\|incomplete"`.
- **Don't run several commands over `ssh` without quoting** (`ssh coder.X 'a; b'`). Pipe longer scripts in: `printf '%s' "$script" | ssh coder.X sh -s -- args`.
- **`systemctl --user` over ssh** needs `export XDG_RUNTIME_DIR=/run/user/$(id -u)` first.
- **Read `coder list --output json` with Python `json.loads(..., strict=False)`**. `jq` fails on the control characters in textarea parameters.
- **The Coder REST API is unreachable**: a Bash hook blocks `curl` to `coder.asana-sand.com`. Use the `coder` CLI. Don't work around the hook.
- **Hands off `~/.zshrc`, `~/.ssh/**`, `~/.aws/**`, `~/.gitconfig`**: Asana's Claude settings deny edits to them. Tell the user what to add instead; don't write to them with shell commands.
- **In zsh, `echo =====` errors** (`=` expansion). Use `echo ----`.

## 1. Snapshot (always first)

```sh
coder list --output json > scratch/list.json   # then parse with Python, strict=False
```
Per box, read `latest_build.status`, `outdated`, `health.healthy`, `automatic_updates`, `latest_build.deadline`, `created_at`.

On each box:
```sh
ssh -o BatchMode=yes coder.dyurinov-N 'export XDG_RUNTIME_DIR=/run/user/$(id -u);
  systemctl --user is-enabled build-watcher.service; systemctl --user is-active build-watcher.service;
  cat /var/asana-config/asana/.tools-data/vagrant_build_status; echo;
  ls ~/.t3/runtime/versions; pgrep -af "t3 serve" | grep -o "versions/[^/]*" | sort -u'
```
The Mac's T3 version: `defaults read "/Applications/T3 Code (Nightly).app/Contents/Info" CFBundleShortVersionString`.

## 2. Bring boxes up

- Run `devboxes` (`~/dev/devbox/bin/devboxes < /dev/null` from Claude). It's idempotent.
- **A stopped box doesn't wake on SSH.** The `coder.*` ProxyCommand has `--disable-autostart=true`, so T3 can't wake it either. Run `coder start dyurinov-N` or `devboxes`.
- **Auto-stop**: 8h TTL (`activity_bump: 0s`). A cron job on the box extends the deadline by 1h whenever there was activity in the last hour: SSH shells, tmux, codez file changes, Claude transcripts, Codex messages. **An open T3 connection isn't activity**, and Codex chat with no file edits may not count either. To keep a box up: `coder schedule stop dyurinov-N manual`. It then bills until you stop it.

## 3. Template updates

- **Every box should have `automatic_updates: always`**: `coder autoupdate dyurinov-N always`. **Recreating a box resets it to `never`**, so set it again after any create.
- **On-demand update**: `coder update dyurinov-N --parameter name=value … < /dev/null`.
  - **No `--yes` flag exists.**
  - **It stops the box before it prompts for new parameters.** If a prompt fails (`EOF`), the box stays stopped; rerun with the missing `--parameter`.
  - **Pass every parameter the new version adds.** Find them with `git grep -n 'data "coder_parameter"' origin/next-master -- asana2/asana/tools/coder/templates/webapp/main.tf` (run `git fetch origin next-master` first) and compare with what the box had. Known so far:
    - `allow_mobile_api_okta_bypass=false`
    - `workspace_creation_warning=Use z devbox create to create a workspace. Creating a workspace through the web UI is not supported.`
  - **`coder start --yes` (and therefore `devboxes`) also prompts** when auto-update brings in a new parameter. Pressing Enter (accepting the default) is fine.
- **An update or restart kills the box's T3 server and every running agent.** Check first: `ssh coder.dyurinov-N 'ps -eo pid,etime,args | grep -E "claude|codex" | grep -v grep'`. If agents are running, ask before updating.
- **Updates keep your files.** The same EC2 instance is stopped and started; `~/.t3`, `~/.claude`, dotfiles and the codez checkout survive. The devbox FAQ says template updates are safe for boxes created after 2026-10-09.

## 4. Health

- `coder list`: `HEALTHY true` and `STATUS Started`. Right after a start, health is `false` until the startup scripts finish (about a minute).
- To wait for startup: `coder ssh --wait=yes dyurinov-N -- true`.
- Checks on a box:
  - `hostnamectl --pretty` should print the workspace name.
  - `~/.config/zsh/t3-ssh.zsh` should exist.
  - To re-apply dotfiles: `/var/lib/coder-agent/coder dotfiles -y https://github.com/dyurinov/dotfiles.git`.

## 5. Build loop (watcher)

- **It's off on these boxes unless started.** They were created with `watcher_enabled=false`.
- **Start it from the Mac** (in `~/sandbox/asana`): `asana2/asana/tools/zoe/bin/z devbox watcher start dyurinov-N < /dev/null`. This enables the systemd unit, so it starts again after restarts, until `watcher stop`.
- **Status**: `z devbox watcher status dyurinov-N`. On the box, the status file is `/var/asana-config/asana/.tools-data/vagrant_build_status` (`Building` / success / failure) and the log is `/var/asana-config/asana/.worktree-data/last_build.log`.
- **Follow it**: `z devbox watcher logs dyurinov-N --tail`. **When stuck**: `z devbox watcher restart dyurinov-N`.
- **What it builds**: only the chosen deployables (default `webapp`; change with `z devbox watcher deployables dyurinov-N --set …`). It skips typechecking.
- **Inotify triggers rebuilds**, so pulling code on the box triggers one too.
- **The first build after starting takes about 10 minutes** on an idle box (measured 2026-11-13).
- **The watcher and agents share one Bazel server.** `z test` from an agent can kill the watcher's build (`Server terminated abruptly … Socket closed`, status `Build failed`). The build can also hang on `Another command (pid=…) is running. Waiting…` long after that pid has exited.
  - Check for agent tests first: `pgrep -af bazel_test_runner`.
  - **Wedged Bazel server**: a build waits forever on `Another command (pid=X) is running … (server_pid=Y)` while `ps -p X` shows nothing. Restarting the watcher doesn't help. With no Bazel clients running (`pgrep -af "bazel|bzl"`), kill the server (`kill Y`, then `kill -9 Y` if needed), then `z devbox watcher restart`. Fixed dyurinov-2 on 2026-11-13.
  - **Rspack "Module not found" for generated files** (`cluster_metadata/generated/web`, `release_revision/current_version`) while the files exist in `bazel-bin`: the Rspack dev server started while Bazel was rewriting those outputs and kept the failed lookups. Once Bazel is up to date, one more `watcher restart` fixes it. Fixed dyurinov-1 and dyurinov-2 this way on 2026-11-13. Expect it on the first build after a branch switch or a big pull.
  - **"Rspack did not finish its initial compilation within 10 minutes"** usually means its Bazel step is blocked. Check `build/rspack-dev-server.log` for `Another command … is running`.
  - Restart the watcher (`z devbox watcher restart`) only once the box is quiet. Restarting it while an agent is testing can kill the agent's Bazel run.
- **Sandbox migrations that run bare `luna/admin` commands fail under the watcher** (`cleanindextables: not found`, exit 127; for example `2026_11_09_create_okvstore_index_text_int_text_text`). The systemd unit only sets `PYTHONPATH`, while login shells also add `luna/admin` to `PATH`.
  - Workaround, on a box with no running tests: `ssh coder.dyurinov-N 'bash -lc "cd /var/asana-config/asana && CONFIG=sand python3 asana2/sandbox/sandbox_migrations/migrate_sandbox.py"'`. It records successful migrations and holds a file lock.
  - The proper fix is in codez: call `$CODEZ/luna/admin/cleanindextables` in `migrate_sandbox.py`, or add `PATH` to `build-watcher.service`.
- **Git is never automatic.** Each box has its own codez clone; nothing pulls or syncs from the Mac. Run `git pull` / `gt sync` on the box.

## 6. T3 Code server version

- **The T3 desktop installs its own version on the box on connect** (`~/.t3/runtime/versions/<v>`, ready once `.install-complete` exists), then runs `t3 serve --host 127.0.0.1 --port 3773`.
- **Pre-install so reconnects are instant**: `~/dev/devbox/bin/devbox-t3-update`. It mirrors the launcher in `~/dev/t3code/packages/ssh/src/tunnel.ts`: GitHub release `pingdotgg/t3code` `v<version>`, `SHA256SUMS`, checksum, smoke test.
- **A running server keeps its old version** until T3 restarts it. Have the user reconnect the environment, or remove it and add it again (⋯ → Remove from this device, then add `coder.dyurinov-N`). Then check that `pgrep -af "t3 serve"` shows the new version path.
- **T3 names the environment from the pretty hostname**, and saves the name only when the environment is added. Every devbox reports `sand000` unless `install.sh` has run.

## 7. Claude & Codex logins

- **`devboxes` checks both.** It reads `~/.claude.json` (`oauthAccount`) and `~/.codex/auth.json` (`auth_mode == "chatgpt"`).
- **Fix commands** (they need the user's browser, so the user runs them):
  ```sh
  ssh -t coder.dyurinov-N claude auth login
  ssh -t coder.dyurinov-N codex login --device-auth
  ```
- **Never run `codex …` on a box to check the login.** The codez wrapper (`bin/codex` → `z ai code --codex`) logs in with the shared `openai_mac_tooling` API key when no ChatGPT login exists.
- **A Codex app-server started before the ChatGPT login keeps using the API key.** That shows up as `Invalid service_tier argument … not allowed for this project`, because `~/.codex/config.toml` has `service_tier = "fast"`. Kill that `codex app-server` process (its parent is `t3 serve`) so T3 starts a new one. T3's "restart agent" doesn't restart it.
- **Claude without a login falls back to Bedrock, which fails on devboxes.** You get a 403 on `autogen_role_sand_devbox`, because the Mac-only credential helper needs `security`. Fix it by logging in. Codez PR #458379 makes devboxes default to first-party auth.
- **`z devbox create` only logs Claude in if `claude-code` is among the AI tools** chosen in `z devbox configure`. Yours is `claude-desktop`, so new boxes always need `claude auth login`.

## 8. T3 environment links

- **A link needs an address the linking server can reach.** Plain http is only allowed on loopback or Tailscale (`apps/server/src/peer/PeerLinks.ts`).
- **Mac → box**: `devbox-forwards` (run by `devboxes`), then link to `http://127.0.0.1:1377N`.
- **Box → box**: on the source box run `~/.config/coderv2/dotfiles/bin/devbox-forwards` (it uses `/var/lib/coder-agent/coder` and the box's Coder session), then on the source box:
  ```sh
  T=$(ls -d ~/.t3/runtime/versions/*/t3 | tail -1)
  # on the target box:
  $T pair --base-dir ~/.t3 --ttl 5m
  # back on the source box, with the printed token:
  $T environment link --base-dir ~/.t3 http://127.0.0.1:1377N --pairing-code <token> --access read-only|approval-required|full-access
  $T environment list --base-dir ~/.t3    # should show "reachable"
  ```
- **Forwards don't survive** a Mac reboot or a box restart. Rerun `devboxes` on the Mac, or the script on the box.
- **Forwards use `--disable-autostart`**, so they never wake a stopped box.
- **Links expire after 30 days.**
- **The Linked environments beta must be on in both T3 environments.**

## 9. Other footguns

- **Workspace names**: hyphens only. Coder rejects underscores.
- **Create boxes with `z devbox create`**, never the Coder web UI. The UI skips commit signing and agent registration.
- **`dyurinov-1` and `-3` were recreated on 2026-11-06**, which is why their auto-update was `never` until 2026-11-13.
- **Pretty-hostname naming for everyone** (one line in `agent_startup_script` in `templates/modules/coder-development/main.tf`) was offered as a codez PR. It hasn't been filed.

## Doing "make sure my devboxes are good"

1. Snapshot (section 1).
2. If any box is stopped, run `devboxes`.
3. Set `autoupdate always` wherever it's `never`.
4. For any box with `outdated` true: check for running agents, then `coder update` with the parameters from section 3. If agents are running, ask first.
5. Start the watcher where it isn't `active`, then wait for the status to leave `Building`. Report failures with the tail of `last_build.log`.
6. Run `devbox-t3-update`, and tell the user which environments need a reconnect to pick up the new version.
7. Run the login check (part of `devboxes`) and report what's missing, with the commands.
8. Report briefly: one line per box (template, health, watcher result, T3 version running/installed, logins), then what the user must do.
