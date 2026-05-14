# TODO

- [ ] Add `devShells` outputs (`ruby-rails`, `go`, etc.) so standard projects can use `use flake <url>#ruby-rails` in `.envrc` with no local `flake.nix` — workhog and xprmnt are the seeds; put these in a **separate repo** (e.g. `sbfaulkner/dev-shells`) for portability across machines
- [ ] Add `templates` output as a fallback for non-standard projects that do need a local `flake.nix`
- [ ] Package `pi` as a Nix derivation (currently a manual `pnpm add -g`)
- [ ] Add more per-project flakes as needed (other repos in `~/src`)
- [ ] Re-enable 1Password `gh` plugin (`home/shell.nix`) — disabled because it causes pi sessions to hang; likely the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) isn't available in pi's spawned shell — check if setting `SSH_AUTH_SOCK` or `OP_PLUGIN_ALIASES_SOURCED` in pi's env helps
- [ ] Add `ripgrep` and `jq` to `home/tools.nix`
- [ ] Configure `programs.zsh.history` — size, deduplication, share across sessions
- [ ] Auto-update strategy: decide whether `reflake` should pull from the remote flake (no local clone needed) or from a local checkout; consider periodic auto-refresh (e.g. on new interactive shell, like oh-my-zsh did) — options include a zsh hook that checks staleness, a launchd timer, or just prompting when the local checkout is behind origin
- [ ] Manage pi config (`~/.pi/`) via home-manager — extensions, skills, and settings need host-specific branching (work vs home have different extensions/skills available); ties into nixifying the pi installation itself
- [ ] Extract work-only shell config from the `isWork` conditional in `home/shell.nix` into a dedicated work module (e.g. `hosts/work-shell.nix` or similar) — currently it's a long `lib.optionalString isWork` block mixed into the shared shell config, which is hard to scan and maintain
- [ ] Audit remaining dotfiles on both machines for candidates to bring under Nix management (e.g. `~/.config/` dirs, `.ssh/config`, starship config, VS Code settings)

