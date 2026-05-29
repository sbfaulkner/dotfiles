# TODO

- [ ] Add `devShells` outputs (`ruby-rails`, `go`, etc.) so standard projects can use `use flake <url>#ruby-rails` in `.envrc` with no local `flake.nix` — workhog and xprmnt are the seeds; put these in a **separate repo** (e.g. `sbfaulkner/dev-shells`) for portability across machines
- [ ] Add `templates` output as a fallback for non-standard projects that do need a local `flake.nix`
- [ ] Add more per-project flakes as needed (other repos in `~/src`)
- [ ] Re-enable 1Password `gh` plugin (`home/shell.nix`) — disabled because it causes pi sessions to hang; likely the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) isn't available in pi's spawned shell — check if setting `SSH_AUTH_SOCK` or `OP_PLUGIN_ALIASES_SOURCED` in pi's env helps
- [x] ~~Add `ripgrep` and `jq` to `home/tools.nix`~~ — done; `rg` is also bundled in the `pi` wrapper for its own use
- [x] ~~Configure `programs.zsh.history` — size, deduplication, share across sessions~~ — done; 10k lines, dedup, shared across sessions, extended timestamps
- [ ] Auto-update strategy: decide whether `reflake` should pull from the remote flake (no local clone needed) or from a local checkout; consider periodic auto-refresh (e.g. on new interactive shell, like oh-my-zsh did) — options include a zsh hook that checks staleness, a launchd timer, or just prompting when the local checkout is behind origin
- [x] ~~Manage pi config (`~/.pi/`) via home-manager~~ — done; seed-only `settings.json`, pi-extensions clone, host-specific model/provider, work-only extra packages
- [ ] Evaluate using Determinate's nix-darwin module/input once the personal bootstrap is stable — likely cleaner than bare `nix.enable = false`, but add it in a focused PR after confirming ownership of the Nix daemon, `/etc/nix/nix.conf`, flake registry/settings, and compatibility with current `nix-darwin`/`home-manager` inputs
- [x] ~~Move encrypted ejson secret files to XDG config~~ — done; shell secrets load `${XDG_CONFIG_HOME:-$HOME/.config}/secrets/default.ejson` and ejson keys stay under ejson's default `/opt/ejson/keys`
- [ ] Decide whether to add a documented restore workflow for populated secret values/private keys via 1Password, AirDrop, or backup restore; current setup seeds an empty default file/keypair if missing but intentionally does not sync secret material from another machine
- [x] ~~Configure a `LESSOPEN`/`lessfilter` pipeline for rich previews in `less`~~ — done for Markdown (`glow`), JSON (`jq`), and YAML (`yq`); `LESS=-RFX`
- [ ] Add a managed `.vimrc` / Vim config via Home Manager; first dig up prior personal Vim settings for useful defaults
- [ ] Audit remaining dotfiles on both machines for candidates to bring under Nix management (e.g. `~/.config/` dirs, `.ssh/config`, starship config, VS Code settings)

