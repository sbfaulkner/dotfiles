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

## Per-Project Flakes

Project-specific dev environments live in each repo as `flake.nix` + `.envrc` and are activated automatically by `direnv` on `cd`. The flake provides the language runtime and any native library dependencies; the project's own tooling (e.g. Bundler, Go modules) manages the rest.

See `TODO.md` for current status and what's still in progress.
