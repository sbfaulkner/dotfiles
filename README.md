# dotfiles

Personal macOS configuration using [Nix](https://nixos.org), [nix-darwin](https://github.com/nix-darwin/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Structure

```
flake.nix        # entry point — inputs and darwinConfigurations
darwin.nix       # system-level config (nix-darwin)
home/
  default.nix    # home-manager entry point
  tools.nix      # user packages
  shell.nix      # zsh, starship, aliases, direnv, 1Password plugins
  git.nix        # git settings and global ignores
hosts/
  work.nix       # work-specific overrides for standalone home-manager
```

## What's Managed

| Layer | Tool | Scope |
|---|---|---|
| System | nix-darwin | macOS settings, Homebrew casks, Nix daemon |
| User packages | home-manager | CLI tools, runtimes, dev utilities |
| Shell | home-manager | zsh, starship, direnv, aliases |
| Git | home-manager | global config and gitignore |
| Casks | Homebrew (declarative) | GUI apps not in nixpkgs (e.g. Godot) |
| Per-project deps | Project flakes + direnv | Language runtimes, native libs |

## Configurations

| Target | Platform | How |
|---|---|---|
| `darwinConfigurations.sbfaulkner` | aarch64-darwin (Apple Silicon) | Full nix-darwin + home-manager |
| `homeConfigurations.work` | aarch64-darwin (Apple Silicon) | Standalone home-manager only (system managed externally) |

The work config (`hosts/work.nix`) disables direnv and packages (provided by the work toolchain) and adds work-specific shell aliases and PATH entries via `isWork`.

## Applying Changes

```bash
reflake
# personal: sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner
# work:     home-manager switch --flake ~/src/github.com/sbfaulkner/dotfiles#work
```

## Bootstrap (new machine)

**1. Install Xcode Command Line Tools** (required by the Nix installer)
```bash
xcode-select --install
```

**2. Install Nix**

Determinate installer (recommended for Apple Silicon):
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```


**3. Bootstrap nix-darwin** (fetches the flake directly from GitHub — no clone needed)
```bash
nix run nix-darwin -- switch --flake github:sbfaulkner/dotfiles#sbfaulkner
```

**4. Clone dotfiles** (for making future edits)
```bash
mkdir -p ~/src/github.com/sbfaulkner
git clone https://github.com/sbfaulkner/dotfiles ~/src/github.com/sbfaulkner/dotfiles
```

After that, use `reflake` for all subsequent changes.

### Work machine

On a machine where Nix is already installed but the system layer is managed
externally, use standalone home-manager. Skip steps 1–2, then:

```bash
nix run home-manager -- switch --flake github:sbfaulkner/dotfiles#work
```

Clone the repo afterward for local edits.

## Per-Project Flakes

Project-specific dev environments live in each repo as `flake.nix` + `.envrc` and are activated automatically by `direnv` on `cd`. The flake provides the language runtime and any native library dependencies; the project's own tooling (e.g. Bundler, Go modules) manages the rest.

## Key Decisions

| Decision | Reason |
|---|---|
| Determinate installer preferred | Better support for Apple Silicon installs |
| pnpm over npm | Consistent with work setup |
| `cleanup = "uninstall"` for Homebrew | Migration complete enough to be strict |
| `allowUnfreePredicate` over `allowUnfree = true` | Only permits explicitly approved packages |
| `try` via `tobi/try-cli` flake | Repo has its own flake with a home-manager module |
| `pi` not in Nix (yet) | Updates too frequently; pnpm global is pragmatic for now |
| `forAllSystems` in project flakes | Portable to Apple Silicon work machine |
| Global gitignore for `.direnv/` | Managed by Nix; no need to add per-project |
| nixpkgs (tracking) | Track nixpkgs and let nix-darwin / home-manager follow it for darwin-specific fixes |
