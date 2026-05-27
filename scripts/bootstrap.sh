#!/usr/bin/env bash
set -euo pipefail

# Bootstrap sbfaulkner/dotfiles on Apple Silicon macOS.
#
# Targets:
#   personal: full nix-darwin + home-manager; can uninstall/reinstall Nix first.
#   work:     standalone home-manager; assumes Nix is managed externally.

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/sbfaulkner/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/src/github.com/sbfaulkner/dotfiles}"
PERSONAL_FLAKE="${PERSONAL_FLAKE:-github:sbfaulkner/dotfiles#sbfaulkner}"
WORK_FLAKE="${WORK_FLAKE:-github:sbfaulkner/dotfiles#work}"
NIX_DARWIN_RUNNER="${NIX_DARWIN_RUNNER:-github:nix-darwin/nix-darwin/master#darwin-rebuild}"
HOME_MANAGER_RUNNER="${HOME_MANAGER_RUNNER:-github:nix-community/home-manager/master}"
DETERMINATE_INSTALLER_URL="${DETERMINATE_INSTALLER_URL:-https://install.determinate.systems/nix}"
HOMEBREW_INSTALLER_URL="${HOMEBREW_INSTALLER_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh}"

TARGET="${TARGET:-auto}"
YES=0
SKIP_UNINSTALL=0
UNINSTALL_ONLY=0

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [options]

Bootstrap sbfaulkner/dotfiles on Apple Silicon macOS.

Options:
  --target personal   Bootstrap the personal nix-darwin configuration.
  --target work       Bootstrap the work standalone home-manager configuration.
  --personal          Shortcut for --target personal.
  --work              Shortcut for --target work.
  --yes               Skip confirmation prompts where supported.
  --skip-uninstall    Personal target only: do not uninstall existing Nix first.
  --uninstall-only    Personal target only: uninstall existing Nix, then stop.
  -h, --help          Show this help.

If --target is omitted, the script asks which target to use. Use an explicit
--target for non-interactive runs.

Environment overrides:
  TARGET                    personal, work, or auto.
  DOTFILES_REPO             Git URL to clone after bootstrap.
  DOTFILES_DIR              Local checkout path.
  PERSONAL_FLAKE            Personal nix-darwin flake ref.
  WORK_FLAKE                Work home-manager flake ref.
  NIX_DARWIN_RUNNER         nix-darwin darwin-rebuild runner flake.
  HOME_MANAGER_RUNNER       home-manager runner flake.
  DETERMINATE_INSTALLER_URL Determinate Nix installer URL.
  HOMEBREW_INSTALLER_URL    Homebrew installer URL.

Personal flow:
  1. Verify macOS + native arm64 shell + Xcode Command Line Tools.
  2. If Nix is already present, offer to uninstall it with /nix/nix-installer.
  3. Install Determinate Nix.
  4. Install Homebrew if /opt/homebrew/bin/brew is missing.
  5. Run nix-darwin with github:sbfaulkner/dotfiles#sbfaulkner.
  6. Clone or update ~/src/github.com/sbfaulkner/dotfiles.

Work flow:
  1. Verify macOS + native arm64 shell + Xcode Command Line Tools.
  2. Require an existing Nix installation.
  3. Run standalone home-manager with github:sbfaulkner/dotfiles#work.
  4. Clone or update ~/src/github.com/sbfaulkner/dotfiles.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      shift
      [[ $# -gt 0 ]] || { echo "--target requires personal or work" >&2; exit 2; }
      TARGET="$1"
      ;;
    --target=*)
      TARGET="${1#--target=}"
      ;;
    --personal)
      TARGET="personal"
      ;;
    --work)
      TARGET="work"
      ;;
    --yes)
      YES=1
      ;;
    --skip-uninstall)
      SKIP_UNINSTALL=1
      ;;
    --uninstall-only)
      UNINSTALL_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

log() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt="$1"

  if [[ "$YES" -eq 1 ]]; then
    log "$prompt yes"
    return 0
  fi

  if [[ ! -r /dev/tty ]]; then
    die "Cannot prompt without a TTY. Re-run with --yes if you want to proceed non-interactively."
  fi

  local reply
  printf '%s [y/N] ' "$prompt" > /dev/tty
  read -r reply < /dev/tty
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

require_command() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || die "Missing required command: $name"
}

validate_target() {
  case "$TARGET" in
    personal|work|auto)
      ;;
    *)
      die "Invalid target '$TARGET'. Expected personal, work, or auto."
      ;;
  esac
}

choose_target() {
  validate_target

  if [[ "$TARGET" != "auto" ]]; then
    return
  fi

  if [[ "$YES" -eq 1 || ! -r /dev/tty ]]; then
    die "Pass --target personal or --target work for non-interactive runs."
  fi

  cat > /dev/tty <<'EOF'

Bootstrap target?
  1) personal — full nix-darwin + home-manager; can uninstall/reinstall Nix
  2) work     — standalone home-manager; assumes externally managed Nix
EOF

  local reply
  while true; do
    printf 'Choose target [personal/work]: ' > /dev/tty
    read -r reply < /dev/tty

    case "$reply" in
      1|personal)
        TARGET="personal"
        return
        ;;
      2|work)
        TARGET="work"
        return
        ;;
      *)
        warn "Please enter personal or work."
        ;;
    esac
  done
}

require_host() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap script is only for macOS."

  if [[ "$(uname -m)" != "arm64" ]]; then
    die "This dotfiles config now targets aarch64-darwin only. Open a native arm64 terminal and retry."
  fi

  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools are not installed. Starting Apple's installer now."
    xcode-select --install || true
    die "Finish the Xcode Command Line Tools install, then re-run this script."
  fi

  require_command curl
  require_command git
}

nix_artifacts_present() {
  command -v nix >/dev/null 2>&1 \
    || [[ -e /nix/nix-installer ]] \
    || [[ -e /nix/store ]] \
    || [[ -e /nix/var ]] \
    || [[ -e /etc/nix ]] \
    || [[ -e /Library/LaunchDaemons/org.nixos.nix-daemon.plist ]] \
    || [[ -e /Library/LaunchDaemons/systems.determinate.nix-daemon.plist ]]
}

uninstall_existing_nix() {
  if [[ "$SKIP_UNINSTALL" -eq 1 ]]; then
    log "Skipping Nix uninstall because --skip-uninstall was provided."
    return
  fi

  if ! nix_artifacts_present; then
    log "No existing Nix installation artifacts detected."
    return
  fi

  confirm "Existing Nix artifacts detected. Uninstall Nix before continuing?" \
    || die "Refusing to continue without a clean Nix uninstall. Re-run with --skip-uninstall to keep the existing install."

  if [[ -x /nix/nix-installer ]]; then
    log "Running Determinate Nix uninstaller."
    local args=(uninstall)
    if [[ "$YES" -eq 1 ]]; then
      args+=(--no-confirm)
    fi
    sudo /nix/nix-installer "${args[@]}"
  else
    cat >&2 <<'EOF'

Existing Nix artifacts were found, but /nix/nix-installer is not available.
This script only performs the automated Determinate Nix uninstall path.

Manual cleanup reference:
  https://docs.determinate.systems/troubleshooting/installation-failed-macos/

Common manual steps after a failed macOS install include:
  - delete the "Nix Store" APFS volume in Disk Utility, if present
  - delete the "Nix Store" encrypted volume password from Keychain Access, if present
  - remove old Nix launch daemon/config remnants if they remain

After manual cleanup, re-run this script.
EOF
    die "Cannot automatically uninstall this Nix installation."
  fi

  hash -r || true

  if [[ -e /nix ]]; then
    warn "A /nix mountpoint may remain until reboot. That can be normal after uninstall."
  fi
}

source_nix_profile() {
  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  hash -r || true
}

install_determinate_nix() {
  source_nix_profile

  if command -v nix >/dev/null 2>&1; then
    log "Nix is already available on PATH."
    return
  fi

  if [[ "$SKIP_UNINSTALL" -eq 1 ]] && nix_artifacts_present; then
    die "Nix artifacts are present but nix is not available. Re-run without --skip-uninstall for a clean retry."
  fi

  confirm "Install Determinate Nix now?" || die "Nix install declined."

  log "Installing Determinate Nix from $DETERMINATE_INSTALLER_URL"
  local args=(install)
  if [[ "$YES" -eq 1 ]]; then
    args+=(--no-confirm)
  fi

  curl --proto '=https' --tlsv1.2 -sSf -L "$DETERMINATE_INSTALLER_URL" | sh -s -- "${args[@]}"
  source_nix_profile

  command -v nix >/dev/null 2>&1 || die "Nix was installed but is not available in this shell. Open a new terminal and re-run."
  log "Installed $(nix --version)."
}

ensure_homebrew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    log "Homebrew already installed at /opt/homebrew."
    return
  fi

  confirm "Install Homebrew now? nix-darwin's homebrew module requires /opt/homebrew/bin/brew." \
    || die "Homebrew install declined. nix-darwin activation would fail without it."

  log "Installing Homebrew from $HOMEBREW_INSTALLER_URL"
  if [[ "$YES" -eq 1 ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALLER_URL")"
  else
    /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALLER_URL")"
  fi

  [[ -x /opt/homebrew/bin/brew ]] || die "Homebrew installer finished, but /opt/homebrew/bin/brew was not found."
}

nix_cmd() {
  nix --extra-experimental-features 'nix-command flakes' "$@"
}

bootstrap_nix_darwin() {
  source_nix_profile
  command -v nix >/dev/null 2>&1 || die "Nix is not available."

  log "Bootstrapping nix-darwin from $PERSONAL_FLAKE"
  nix_cmd run "$NIX_DARWIN_RUNNER" -- switch --flake "$PERSONAL_FLAKE"
}

bootstrap_home_manager_work() {
  source_nix_profile
  command -v nix >/dev/null 2>&1 || die "Nix is not available. Install/use the externally managed Nix setup first."

  log "Bootstrapping standalone home-manager from $WORK_FLAKE"
  nix_cmd run "$HOME_MANAGER_RUNNER" -- switch --flake "$WORK_FLAKE"
}

clone_dotfiles() {
  local parent
  parent="$(dirname "$DOTFILES_DIR")"
  mkdir -p "$parent"

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating existing dotfiles checkout at $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" fetch origin main
    git -C "$DOTFILES_DIR" checkout main
    git -C "$DOTFILES_DIR" pull --ff-only origin main
  elif [[ -e "$DOTFILES_DIR" ]]; then
    warn "$DOTFILES_DIR already exists but is not a Git checkout; leaving it untouched."
  else
    log "Cloning dotfiles to $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

bootstrap_personal() {
  sudo -v

  uninstall_existing_nix

  if [[ "$UNINSTALL_ONLY" -eq 1 ]]; then
    log "Stopped after uninstall because --uninstall-only was provided."
    exit 0
  fi

  install_determinate_nix
  ensure_homebrew
  bootstrap_nix_darwin
  clone_dotfiles
}

bootstrap_work() {
  if [[ "$UNINSTALL_ONLY" -eq 1 ]]; then
    die "--uninstall-only only applies to --target personal."
  fi

  if [[ "$SKIP_UNINSTALL" -eq 1 ]]; then
    warn "--skip-uninstall is ignored for --target work."
  fi

  bootstrap_home_manager_work
  clone_dotfiles
}

print_next_steps() {
  cat <<EOF

Bootstrap complete for target: $TARGET

Recommended next steps:
  1. Open a new terminal so zsh/Home Manager environment changes are loaded.
  2. Confirm the checkout is present:
       cd "$DOTFILES_DIR"
  3. For future updates, run:
       reflake
EOF

  if [[ "$TARGET" == "personal" ]]; then
    cat <<'EOF'

If the installer failed before or macOS still shows an old Nix Store volume,
follow Determinate's cleanup notes and then rerun this script:
  https://docs.determinate.systems/troubleshooting/installation-failed-macos/
EOF
  fi
}

main() {
  choose_target
  require_host

  log "Bootstrap target: $TARGET"
  log "Checkout path:    $DOTFILES_DIR"

  case "$TARGET" in
    personal)
      log "Personal flake:   $PERSONAL_FLAKE"
      bootstrap_personal
      ;;
    work)
      log "Work flake:       $WORK_FLAKE"
      bootstrap_work
      ;;
  esac

  print_next_steps
}

main "$@"
