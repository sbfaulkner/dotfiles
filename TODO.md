# Nixifying This Mac

A record of migrating from Homebrew + mise + oh-my-zsh to a fully declarative
Nix + nix-darwin + home-manager setup.

## What We Did

### Foundation

- Installed Nix via the official installer (Determinate dropped x86_64 support)
- Enabled flakes in `/etc/nix/nix.conf`
- Created dotfiles repo at `~/src/github.com/sbfaulkner/dotfiles`
  → `github.com/sbfaulkner/dotfiles`
- Bootstrapped nix-darwin and integrated home-manager as a nix-darwin module

### System Config (`darwin.nix`)

- `nixpkgs.config.allowUnfreePredicate` — allows only explicitly approved unfree
  packages (`1password-cli`)
- `system.primaryUser = "sbfaulkner"` — required by nix-darwin for the homebrew
  module
- Homebrew module declared with `cleanup = "uninstall"` — only the `godot` cask
  remains; everything else moved to Nix

### User Tools (`home/tools.nix`)

Packages installed via home-manager (all from nixpkgs):

- `ejson` — encrypted secrets management
- `fastfetch` — system info summary
- `fd` — fast alternative to find
- `gh` — GitHub CLI (with 1Password credential injection)
- `nodejs` — JavaScript runtime
- `pnpm` — package manager; global packages land in `$PNPM_HOME`

`direnv` + `nix-direnv` — automatically activates per-project dev shells on `cd`.

### Shell (`home/shell.nix`)

- **zsh** managed by home-manager — oh-my-zsh removed entirely
- **starship** — replaces spaceship prompt
- **cdpath** — shortcuts for `~/src/github.com/sbfaulkner`, `~/src`, etc.
- **aliases** — `a=alias`, `h=history`, `rebuild=sudo darwin-rebuild switch ...`
- **try** — via `github:tobi/try-cli` flake, shell function wired automatically
- **1Password shell plugins** — `op` from Nix, credential injection for `gh`

### Git (`home/git.nix`)

- `programs.git.settings` — name, email, editor (VS Code), `pull.rebase = true`
- `programs.git.ignores` — global gitignore: `.direnv/`, `.DS_Store`

### External Flake Inputs

| Input | URL | Purpose |
|---|---|---|
| nixpkgs | `github:NixOS/nixpkgs/nixpkgs-unstable` | all packages |
| nix-darwin | `github:nix-darwin/nix-darwin/master` | macOS system config |
| home-manager | `github:nix-community/home-manager` | user environment |
| 1Password shell plugins | `github:1Password/shell-plugins` | op + gh credential injection |
| try-cli | `github:tobi/try-cli` | try binary + zsh shell function |

### Cleanup

- Removed from Homebrew: fd, gh, ejson, node, 1password-cli, nginx, prometheus,
  grafana, node_exporter, screenfetch, glances, stress, ragel, libyaml, fastfetch
- Stopped and removed all lingering launchd services (prometheus, grafana, nginx,
  node_exporter)
- Deleted: `~/.oh-my-zsh`, `~/.zshrc.bak`, `~/go`
- Cleaned `/usr/local/bin` — only `brew`, `code`, `godot` remain
- `~/.local` is clean — only pnpm, gh, and nix/home-manager state remain

### Per-Project Flakes

**`xprmnt`** (Go) — ✅ working

- `flake.nix` + `.envrc` committed
- Provides: `go_1_26`, `gotools` (goyacc), `ragel`
- `direnv allow` — activates automatically on `cd`

**`workhog`** (Ruby/Rails) — ✅ working

- `flake.nix` + `.envrc` committed
- Provides: `ruby_3_3`, `sqlite`, `libyaml` (psych gem)
- `bundle install` verified working

---

## Reflake Command

```bash
reflake
# expands to: sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner
```

---

## What's Left

### Immediate

- [x] Finish `workhog` flake: add `.envrc`, test `bundle install`, commit
- [x] Push dotfiles to GitHub

### Follow-up

- [ ] Work machine: set up standalone home-manager on top of work-managed base environment
  - `home/default.nix` hardcodes `username`/`homeDirectory` — parameterize or move to host-specific modules before enabling `homeConfigurations.work`
- [ ] Add `devShells` outputs (`ruby-rails`, `go`, etc.) so standard projects can use `use flake <url>#ruby-rails` in `.envrc` with no local `flake.nix` — workhog and xprmnt are the seeds; put these in a **separate repo** (e.g. `sbfaulkner/dev-shells`) for portability across machines
- [ ] Add `templates` output as a fallback for non-standard projects that do need a local `flake.nix`
- [ ] Package `pi` as a Nix derivation (currently a manual `pnpm add -g`)
- [ ] Add more per-project flakes as needed (other repos in `~/src`)
- [ ] Re-enable 1Password `gh` plugin (`home/shell.nix`) — disabled because it causes pi sessions to hang; likely the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) isn't available in pi's spawned shell — check if setting `SSH_AUTH_SOCK` or `OP_PLUGIN_ALIASES_SOURCED` in pi's env helps
- [ ] Add `ripgrep` and `jq` to `home/tools.nix`
- [ ] Configure `programs.zsh.history` — size, deduplication, share across sessions
- [ ] Manage pi config (`~/.pi/`) via home-manager — extensions, skills, and settings need host-specific branching (work vs home have different extensions/skills available); ties into nixifying the pi installation itself
- [ ] Audit remaining dotfiles on both machines for candidates to bring under Nix management (e.g. `~/.config/` dirs, `.ssh/config`, starship config, VS Code settings)

---

## Key Decisions

| Decision | Reason |
|---|---|
| Official Nix installer over Determinate | Determinate dropped x86_64-darwin support |
| pnpm over npm | Consistent with work setup |
| `cleanup = "uninstall"` for Homebrew | Migration complete enough to be strict |
| `allowUnfreePredicate` over `allowUnfree = true` | Only permits explicitly approved packages |
| `try` via `tobi/try-cli` flake | Repo has its own flake with a home-manager module |
| `pi` not in Nix (yet) | Updates too frequently; pnpm global is pragmatic for now |
| `forAllSystems` in project flakes | Portable to Apple Silicon work machine |
| Global gitignore for `.direnv/` | Managed by Nix; no need to add per-project |
