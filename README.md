# dotfiles

Personal macOS configuration using [Nix](https://nixos.org), [nix-darwin](https://github.com/nix-darwin/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Structure

```
flake.nix        # entry point — inputs and darwinConfigurations
darwin.nix       # system-level config (nix-darwin)
home/
  default.nix    # home-manager entry point
  ghostty.nix    # shared Ghostty terminal config
  tools.nix      # user packages
  shell.nix      # zsh, starship, aliases, direnv, 1Password plugins
  git.nix        # git settings and global ignores
hosts/
  personal.nix   # personal-machine home-manager overrides
  work.nix       # work-specific overrides for standalone home-manager
  work-shell.nix # work-specific zsh aliases, PATH, and init
pkgs/
  pi-coding-agent.nix # local Pi release package
scripts/
  bootstrap.sh    # clean personal/work bootstrap/retry script
```

## What's Managed

| Layer | Tool | Scope |
|---|---|---|
| System | nix-darwin | macOS settings, Homebrew casks, Nix daemon |
| User packages | home-manager | CLI tools, runtimes, dev utilities |
| Shell | home-manager | zsh, starship, direnv, aliases |
| Git | home-manager | global config and gitignore |
| Casks | Homebrew (declarative) | Personal GUI apps (1Password, Chrome, Ghostty, Godot) |
| Per-project deps | Project flakes + direnv | Language runtimes, native libs |

## Configurations

| Target | Platform | How |
|---|---|---|
| `darwinConfigurations.sbfaulkner` | aarch64-darwin (Apple Silicon) | Full nix-darwin + home-manager |
| `homeConfigurations.work` | aarch64-darwin (Apple Silicon) | Standalone home-manager only (system managed externally) |

The shared home-manager config stays in `home/`. Host-specific home-manager overrides live in `hosts/`: `hosts/personal.nix` adds the personal `reflake` command, and `hosts/work.nix` imports `hosts/work-shell.nix` for work aliases, PATH entries, and shell initialization.

## Applying Changes

```bash
reflake
# personal: sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner
# work:     home-manager switch --flake ~/src/github.com/sbfaulkner/dotfiles#work
```

## Bootstrap (new machine)

Recommended bootstrap entry point for any Apple Silicon Mac:

```bash
script="$(mktemp)"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/sbfaulkner/dotfiles/main/scripts/bootstrap.sh \
  -o "$script"
bash "$script"
rm -f "$script"
```

If `--target` is omitted, the script asks whether to bootstrap `personal` or
`work`.

For a clean retry on a personal Mac, run the personal target explicitly:

```bash
script="$(mktemp)"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/sbfaulkner/dotfiles/main/scripts/bootstrap.sh \
  -o "$script"
bash "$script" --target personal
rm -f "$script"
```

The personal target checks prerequisites, offers to uninstall an existing
Determinate Nix install via `/nix/nix-installer uninstall`, installs Determinate
Nix, installs Homebrew if needed, runs nix-darwin from the GitHub flake, installs
personal Homebrew casks (1Password, Ghostty, Godot, and Google Chrome), and
clones this repo to `~/src/github.com/sbfaulkner/dotfiles`.

For a non-interactive personal run, pass both `--target personal` and `--yes`:

```bash
script="$(mktemp)"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/sbfaulkner/dotfiles/main/scripts/bootstrap.sh \
  -o "$script"
bash "$script" --target personal --yes
rm -f "$script"
```

Manual personal equivalent:

**1. Install Xcode Command Line Tools** (required by the Nix installer and `git`)
```bash
xcode-select --install
```

**2. Install Nix**

Determinate installer (recommended for Apple Silicon):
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Because Determinate manages the Nix daemon and `/etc/nix/nix.conf`, this
nix-darwin configuration sets `nix.enable = false` and leaves the Nix
installation itself to Determinate.

**3. Install Homebrew** (required by the nix-darwin Homebrew module)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**4. Bootstrap nix-darwin** (fetches the flake directly from GitHub — no clone needed)
```bash
sudo -H /nix/var/nix/profiles/default/bin/nix --extra-experimental-features 'nix-command flakes' run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake github:sbfaulkner/dotfiles#sbfaulkner
```

**5. Clone dotfiles** (for making future edits)
```bash
mkdir -p ~/src/github.com/sbfaulkner
git clone https://github.com/sbfaulkner/dotfiles.git ~/src/github.com/sbfaulkner/dotfiles
```

After that, open a new terminal and use `reflake` for all subsequent changes.

### Work machine

On a machine where Nix is already installed but the system layer is managed
externally, use standalone home-manager:

```bash
script="$(mktemp)"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/sbfaulkner/dotfiles/main/scripts/bootstrap.sh \
  -o "$script"
bash "$script" --target work
rm -f "$script"
```

Manual work equivalent:

```bash
nix --extra-experimental-features 'nix-command flakes' run github:nix-community/home-manager/master -- switch --flake github:sbfaulkner/dotfiles#work
```

Clone the repo afterward for local edits if you use the manual command.

## Ghostty

Home Manager manages shared Ghostty config at `~/.config/ghostty/config` for
both personal and work machines. The personal nix-darwin configuration installs
the Ghostty app via Homebrew cask; work machines manage the config only and leave
the app install to the external work setup.

On activation, Home Manager backs up legacy macOS-specific Ghostty config files
from `~/Library/Application Support/com.mitchellh.ghostty/` to
`*.before-home-manager` so they cannot override the managed XDG config.

## Per-Project Flakes

Project-specific dev environments live in each repo as `flake.nix` + `.envrc` and are activated automatically by `direnv` on `cd`. The flake provides the language runtime and any native library dependencies; the project's own tooling (e.g. Bundler, Go modules) manages the rest.

## Key Decisions

| Decision | Reason |
|---|---|
| Determinate installer preferred | Better support for Apple Silicon installs |
| `nix.enable = false` in nix-darwin | Determinate manages the Nix daemon and `/etc/nix/nix.conf`; nix-darwin manages the rest |
| pnpm over npm | Consistent with work setup |
| `cleanup = "uninstall"` for Homebrew | Migration complete enough to be strict |
| `allowUnfreePredicate` over `allowUnfree = true` | Only permits explicitly approved packages |
| `try` via `tobi/try-cli` flake | Repo has its own flake with a home-manager module |
| `pi` not in Nix (yet) | Updates too frequently; pnpm global is pragmatic for now |
| Ghostty config uses XDG path | Shared across personal and work; legacy macOS config is backed up so it cannot override XDG |
| `forAllSystems` in project flakes | Portable to Apple Silicon work machine |
| Global gitignore for `.direnv/` | Managed by Nix; no need to add per-project |
| nixpkgs-unstable tracking branch | Track current Darwin fixes while `flake.lock` pins exact revisions |
| Home Manager release check disabled | Intentional `nixpkgs-unstable` + `home-manager/master` pairing can report different release numbers |
