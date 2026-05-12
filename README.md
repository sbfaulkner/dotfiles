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

## Applying Changes

```bash
rebuild
# expands to: sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner
```

## Bootstrap (new machine)

**1. Install Xcode Command Line Tools**
```bash
xcode-select --install
```

**2. Install Nix**

Official installer (required for x86_64 — Determinate dropped support):
```bash
sh <(curl -L https://nixos.org/nix/install)
```

Or Determinate installer (Apple Silicon only):
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**3. Clone dotfiles**
```bash
mkdir -p ~/src/github.com/sbfaulkner
git clone https://github.com/sbfaulkner/dotfiles ~/src/github.com/sbfaulkner/dotfiles
```

**4. Bootstrap nix-darwin** (`rebuild` alias doesn't exist yet on first run)
```bash
nix run nix-darwin -- switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner
```

After that, use `rebuild` for all subsequent changes.

### Managed machine (e.g. work)

On a machine where you can't run nix-darwin, use standalone home-manager instead. Steps 1–3 are the same, then:

```bash
nix run home-manager -- switch --flake ~/src/github.com/sbfaulkner/dotfiles#<host>
```

> **Note:** standalone home-manager configuration is not yet set up in this flake — see TODO.md.

## Per-Project Flakes

Project-specific dev environments live in each repo as `flake.nix` + `.envrc` and are activated automatically by `direnv` on `cd`. The flake provides the language runtime and any native library dependencies; the project's own tooling (e.g. Bundler, Go modules) manages the rest.

See `TODO.md` for current status and what's still in progress.

## Work Machine Compatibility

This config is designed to eventually share modules with the work machine
(Apple Silicon, aarch64-darwin). At work, the system-level Nix setup is
managed externally, so only **standalone home-manager** should be used there
(no nix-darwin).

The `flake.nix` has a commented-out `homeConfigurations.work` target for this.
When enabling it, note that `home/default.nix` currently hardcodes `username`
and `homeDirectory` — these will need to be parameterized or moved to
host-specific modules.
