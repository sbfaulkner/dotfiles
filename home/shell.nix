{ lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    defaultKeymap = "viins";

    history = {
      size = 10000;          # HISTSIZE — lines kept in memory
      save = 10000;          # SAVEHIST — lines written to file
      ignoreDups = true;     # setopt HIST_IGNORE_DUPS — skip consecutive dupes
      ignoreAllDups = true;  # setopt HIST_IGNORE_ALL_DUPS — remove older dupe
      ignoreSpace = true;    # setopt HIST_IGNORE_SPACE — space-prefixed cmds stay private
      share = true;          # setopt SHARE_HISTORY — sync across sessions
      extended = true;       # setopt EXTENDED_HISTORY — timestamps in history file
    };

    shellAliases = {
      a = "alias";
      h = "history";
    };

    initContent = lib.mkOrder 950 ''
      # CDPATH — all org dirs under ~/src/github.com, plus src and home.
      cdpath=($HOME/src/github.com/*(N/) $HOME/src $HOME)

      # Restore Ctrl-R incremental search in vi mode
      bindkey -M viins '^R' history-incremental-search-backward
      bindkey -M viins '^S' history-incremental-search-forward

      # Shell options
      unsetopt autocd
      unsetopt nomatch
      unsetopt hist_verify
      setopt rm_star_silent

      # secrets — load ejson secrets into env
      # Supports: secrets [name]
      #           secrets -e|--edit [name]   # edit plaintext and re-encrypt when saved
      secrets() {
        local edit=0
        local name

        while [ $# -gt 0 ]; do
          case "$1" in
            -e|--edit)
              edit=1
              shift
              ;;
            --)
              shift
              break
              ;;
            -*)
              echo "Unknown option: $1" >&2
              return 1
              ;;
            *)
              name="$1"
              shift
              ;;
          esac
        done

        local EJSON="''${XDG_CONFIG_HOME:-$HOME/.config}/secrets/''${name:-default}.ejson"

        if [ "$edit" -eq 1 ]; then
          if [ ! -f "$EJSON" ]; then
            echo "Secrets file not found: $EJSON" >&2
            return 1
          fi

          if ! command -v ejson >/dev/null 2>&1; then
            echo "ejson is not installed or not on PATH" >&2
            return 1
          fi

          local orig tmp
          orig="$(mktemp "${TMPDIR:-/tmp}/secrets.orig.XXXXXX")" || return 1
          tmp="$(mktemp "${TMPDIR:-/tmp}/secrets.edit.XXXXXX")" || { rm -f "$orig"; return 1; }
          trap 'rm -f "$orig" "$tmp"' EXIT

          # Decrypt to orig (plaintext) for comparison, and copy to tmp for editing
          if ! ejson decrypt "$EJSON" >"$orig" 2>/dev/null; then
            echo "Failed to decrypt $EJSON — do you have the private key in /opt/ejson/keys?" >&2
            return 1
          fi
          cp "$orig" "$tmp"

          ${EDITOR:-vi} "$tmp"

          if cmp -s "$orig" "$tmp"; then
            echo "No changes made to $EJSON"
            return 0
          fi

          # Re-encrypt the edited plaintext and replace the original ejson file
          if ejson encrypt "$tmp" >/dev/null 2>&1; then
            mv "$tmp" "$EJSON"
            echo "Re-encrypted secrets: $EJSON"
            rm -f "$orig"
            return 0
          else
            echo "Failed to re-encrypt edited secrets" >&2
            return 1
          fi
        fi

        if [ -f "$EJSON" ]; then
          echo "Loading secrets: $EJSON"
          eval "$(ejson2env "$EJSON")"
        else
          echo "Secrets file not found: $EJSON"
          return 1
        fi
      }

      # load default secrets at shell startup (only if the file exists)
      if [ -f "''${XDG_CONFIG_HOME:-$HOME/.config}/secrets/default.ejson" ]; then
        secrets
      fi
    '';
  };

  # Seed an empty default secrets file on new machines. Existing secrets are
  # never overwritten; populated secret values are restored out-of-band.
  home.activation.seedDefaultEjsonSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    secrets_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/secrets"
    default_ejson="$secrets_dir/default.ejson"
    keydir="/opt/ejson/keys"

    if [ ! -f "$default_ejson" ]; then
      if [ ! -d "$keydir" ] || [ ! -w "$keydir" ]; then
        echo "Cannot seed $default_ejson because $keydir is not writable." >&2
        exit 1
      fi

      run mkdir -p "$secrets_dir"
      public_key="$(${pkgs.ejson}/bin/ejson keygen --write)" || exit 1

      cat > "$default_ejson" <<SECRETS_EOF
{
  "_public_key": "$public_key",
  "environment": {}
}
SECRETS_EOF

      verboseEcho "Seeded empty ejson secrets file at $default_ejson"
    fi
  '';

  # PATH additions
  home.sessionPath = [
    "$HOME/scripts"
    "$HOME/bin"
  ];

  # try — experiment directory manager
  programs.try = {
    enable = true;
    path = "~/src/tries";
  };

  # 1Password shell plugins — installs op from Nix and enables credential
  # injection for specified CLIs. Replaces the Homebrew 1password-cli cask.
  programs._1password-shell-plugins = {
    enable = true;
    # plugins = with pkgs; [ gh ];  # disabled: causes pi sessions to hang
  };

  # Starship replaces spaceship. home-manager wires it into zsh automatically.
  programs.starship.enable = true;
  programs.starship.settings = {
    # Disable slow modules
    git_status.disabled = true;

    # Disable noisy modules that aren't actionable day-to-day
    gcloud.disabled = true;
    nix_shell.disabled = true;
    package.disabled = true;
  };
}
