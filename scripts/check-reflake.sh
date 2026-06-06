#!/usr/bin/env bash
set -euo pipefail

# Minimal check-reflake script
# - Detects remote changes via git ls-remote
# - Detects local changes vs last successful reflake (LAST_HEAD in state file)
# - Modes: prompt (default), auto, auto-pull, disabled

DOTFILES="${DOTFILES:-$HOME/src/github.com/sbfaulkner/dotfiles}"
STATE_DIR="${REFLAKE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}"
STATE_FILE="$STATE_DIR/reflake-last"
LOCK_DIR="$STATE_DIR/reflake-lock"
MODE="${REFLAKE_MODE:-prompt}"
AGE_DAYS="${REFLAKE_AGE_DAYS:-7}"

usage(){
  cat <<EOF
Usage: $(basename "$0") [--force] [--yes] [--preview] [--age DAYS]
  --force    ignore timestamp/age gating
  --yes      run without prompting
  --preview  run non-activating build instead of switch
  --age DAYS override default age (days)
EOF
  exit 2
}

FORCE=0
YES=0
PREVIEW=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --yes) YES=1; shift ;;
    --preview) PREVIEW=1; shift ;;
    --age) AGE_DAYS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

mkdir -p "$STATE_DIR"

lock(){
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  else
    # already locked
    return 1
  fi
}

unlock(){
  rm -rf "$LOCK_DIR" || true
}

# Acquire lock to avoid concurrent prompts/runs. If lock cannot be obtained,
# another session is already running the check; exit quietly.
if ! lock; then
  exit 0
fi

trap "unlock" EXIT INT TERM

# simple tty check
is_tty(){ [[ -t 1 ]] ; }

# read recorded head
recorded_head=""
if [[ -f "$STATE_FILE" ]]; then
  recorded_head=$(sed -n 's/^LAST_HEAD=//p' "$STATE_FILE" || true)
fi

# determine local head and branch
if [[ -d "$DOTFILES/.git" ]]; then
  branch=$(git -C "$DOTFILES" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  local_head=$(git -C "$DOTFILES" rev-parse --short HEAD 2>/dev/null || true)
else
  echo "Dotfiles path $DOTFILES is not a git checkout." >&2
  exit 2
fi

# fast remote check via ls-remote
remote_head=""
if [[ -n "$branch" ]]; then
  remote_head=$(git -C "$DOTFILES" ls-remote origin "refs/heads/$branch" 2>/dev/null | cut -f1 || true)
fi

remote_changed=0
local_changed=0

if [[ -n "$remote_head" && "$remote_head" != "$local_head" ]]; then
  remote_changed=1
elif [[ -n "$recorded_head" && "$local_head" != "$recorded_head" ]]; then
  local_changed=1
fi

# age gating: check last epoch
now_epoch=$(date +%s)
last_epoch=0
if [[ -f "$STATE_FILE" ]]; then
  last_epoch=$(sed -n 's/^LAST_EPOCH=//p' "$STATE_FILE" || echo 0)
fi
age_seconds=$(( AGE_DAYS * 86400 ))
elapsed=$(( now_epoch - last_epoch ))
if [[ $FORCE -eq 0 && $elapsed -lt $age_seconds && $remote_changed -eq 0 && $local_changed -eq 0 ]]; then
  # nothing to do and not old enough
  exit 0
fi

# if disabled mode
if [[ "$MODE" == "disabled" ]]; then
  exit 0
fi

# if preview requested, run build-only
run_preview(){
  echo "Running preview build (non-activating)..."
  if command -v home-manager >/dev/null 2>&1; then
    home-manager build --flake "$DOTFILES#work"
    return $?
  elif command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild build --flake "$DOTFILES#sbfaulkner"
    return $?
  else
    echo "No home-manager or darwin-rebuild available for preview." >&2
    return 2
  fi
}

# check repo clean
repo_clean() {
  if git -C "$DOTFILES" diff --quiet --ignore-submodules -- && git -C "$DOTFILES" diff --cached --quiet; then
    return 0
  else
    return 1
  fi
}

# run reflake (choose appropriate tool)
run_reflake(){
  echo "Running reflake..."
  if command -v reflake >/dev/null 2>&1; then
    reflake
    return $?
  elif command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$DOTFILES#work"
    return $?
  elif command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake "$DOTFILES#sbfaulkner"
    return $?
  else
    echo "No reflake command found; please ensure 'reflake' alias or home-manager/darwin-rebuild is available." >&2
    return 2
  fi
}

# decide action
if [[ $remote_changed -eq 0 && $local_changed -eq 0 ]]; then
  # nothing changed — update epoch to avoid repeated prompts
  printf "LAST_EPOCH=%s\n" "$now_epoch" > "$STATE_FILE"
  exit 0
fi

# If non-interactive and not --yes, do nothing (avoid background prompts)
if ! is_tty && [[ $YES -eq 0 ]]; then
  # write status but do not prompt
  printf "LAST_EPOCH=%s\nLAST_HEAD=%s\n" "$now_epoch" "$local_head" > "$STATE_FILE"
  exit 0
fi

# prompt or auto behavior
action_performed=0
if [[ $remote_changed -eq 1 ]]; then
  case "$MODE" in
    prompt)
      printf "Remote has updates (origin/%s != local). Pull & reflake? [y/N] " "$branch"
      read -r ans || ans="n"
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        if repo_clean; then
          git -C "$DOTFILES" pull --ff-only origin "$branch"
          run_reflake || exit $?
          action_performed=1
        else
          echo "Repo dirty; please stash/commit before auto-pull." >&2
          exit 3
        fi
      else
        echo "Skipped."; exit 0
      fi
      ;;
    auto-pull)
      if repo_clean; then
        git -C "$DOTFILES" pull --ff-only origin "$branch"
        run_reflake || exit $?
        action_performed=1
      else
        echo "Repo dirty; skipping auto-pull." >&2; exit 3
      fi
      ;;
    auto)
      # in auto mode, do not pull; require manual pull but run reflake if local differs
      if repo_clean; then
        run_reflake || exit $?
        action_performed=1
      else
        echo "Repo dirty; skipping auto reflake." >&2; exit 3
      fi
      ;;
    *)
      echo "Unknown REFLAKE_MODE: $MODE" >&2; exit 2 ;;
  esac
elif [[ $local_changed -eq 1 ]]; then
  case "$MODE" in
    prompt)
      printf "Local checkout changed since last reflake. Run reflake now? [y/N] "
      read -r ans || ans="n"
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        run_reflake || exit $?
        action_performed=1
      else
        echo "Skipped."; exit 0
      fi
      ;;
    auto|auto-pull)
      if repo_clean; then
        run_reflake || exit $?
        action_performed=1
      else
        echo "Repo dirty; skipping auto reflake." >&2; exit 3
      fi
      ;;
    *) echo "Unknown REFLAKE_MODE: $MODE" >&2; exit 2 ;;
  esac
fi

# on success, record LAST_HEAD & LAST_EPOCH
if [[ $action_performed -eq 1 ]]; then
  now_epoch=$(date +%s)
  printf "LAST_EPOCH=%s\nLAST_HEAD=%s\n" "$now_epoch" "$local_head" > "$STATE_FILE"
fi

exit 0
