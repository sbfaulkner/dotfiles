# TODO

- [ ] Add `devShells` outputs (`ruby-rails`, `go`, etc.) so standard projects can use `use flake <url>#ruby-rails` in `.envrc` with no local `flake.nix` — workhog and xprmnt are the seeds; put these in a **separate repo** (e.g. `sbfaulkner/dev-shells`) for portability across machines
- [ ] Add `templates` output as a fallback for non-standard projects that do need a local `flake.nix`
- [ ] Add more per-project flakes as needed (other repos in `~/src`)
- [ ] Re-enable 1Password `gh` plugin (`home/shell.nix`) — the 1Password shell-plugins flake is already included and the module is enabled, but `plugins = with pkgs; [ gh ];` is currently commented out because it causes pi sessions to hang. Investigate whether making the 1Password agent socket available to pi (SSH_AUTH_SOCK, OP_PLUGIN_ALIASES_SOURCED, or adjusting pi's spawn environment) resolves the issue
- [x] ~~Add `ripgrep` and `jq` to `home/tools.nix`~~ — done; `rg` is also bundled in the `pi` wrapper for its own use
- [x] ~~Configure `programs.zsh.history` — size, deduplication, share across sessions~~ — done; 10k lines, dedup, shared across sessions, extended timestamps
- [x] Auto-update strategy — implemented: a lightweight zsh-initiated check runs once-per-login to detect staleness and optionally prompt or auto-run `reflake`.
  - The helper script is deployed to $XDG_CONFIG_HOME/dotfiles/check-reflake by home/tools.nix and invoked in hosts/personal.nix and hosts/work-shell.nix during shell init (background, non-blocking).
  - Modes: prompt (default), auto, auto-pull, disabled. Configure via environment variables: REFLAKE_MODE, REFLAKE_AGE_DAYS, REFLAKE_STATE_DIR.
  - The script detects remote changes (git ls-remote), local changes/dirty tree, and last successful reflake (LAST_HEAD in state file) and will run or prompt accordingly.
- [x] ~~Manage pi config (`~/.pi/`) via home-manager~~ — done; seed-only `settings.json`, pi-extensions clone, host-specific model/provider, work-only extra packages
- [ ] Evaluate using Determinate's nix-darwin module/input once the personal bootstrap is stable — likely cleaner than bare `nix.enable = false`, but add it in a focused PR after confirming ownership of the Nix daemon, `/etc/nix/nix.conf`, flake registry/settings, and compatibility with current `nix-darwin`/`home-manager` inputs
- [x] ~~Move encrypted ejson secret files to XDG config~~ — done; shell secrets load `${XDG_CONFIG_HOME:-$HOME/.config}/secrets/default.ejson` and ejson keys stay under ejson's default `/opt/ejson/keys`
- [ ] Decide whether to add a documented restore workflow for populated secret values/private keys via 1Password, AirDrop, or backup restore; current setup seeds an empty default file/keypair if missing but intentionally does not sync secret material from another machine — **deprioritized for now**
- [x] ~~Configure a `LESSOPEN`/`lessfilter` pipeline for rich previews in `less`~~ — done for Markdown (pinned `glow` 1.5.1), JSON (`jq`), and YAML (`yq`); `LESS=-RFX`; lessfilter is wrapped with pinned runtime inputs
- [ ] Add a managed `.vimrc` / Vim config via Home Manager; first dig up prior personal Vim settings for useful defaults
- [ ] Audit remaining dotfiles on both machines for candidates to bring under Nix management (e.g. `~/.config/` dirs, `.ssh/config`, starship config, VS Code settings)

