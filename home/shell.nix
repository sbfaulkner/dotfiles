{ pkgs, lib, ... }:

let
  starshipVersion = "1.25.1";
  # Starship 1.25 adds git_branch.use_git_executable, which is needed for
  # repositories that use Git's reftable backend (e.g. Shopify's world repo).
  # Target Apple Silicon (aarch64)
  starshipTarget = "aarch64-apple-darwin";
  starshipHash = "sha256-/ok0mYmKwYE8FccucpP/tTdZBjZ5S3/nPhMmR7V/lW8=";

  starshipSrc = pkgs.fetchzip {
    url = "https://github.com/starship/starship/releases/download/v${starshipVersion}/starship-${starshipTarget}.tar.gz";
    hash = starshipHash;
    stripRoot = false;
  };
  starshipPackage = pkgs.runCommand "starship-${starshipVersion}" {
    meta.mainProgram = "starship";
  } ''
    mkdir -p $out/bin
    cp ${starshipSrc}/starship $out/bin/starship
    chmod +x $out/bin/starship
  '';
in
{
  programs.zsh = {
    enable = true;

    defaultKeymap = "viins";

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
      secrets() {
        local EJSON="$HOME/.secrets.d/''${1:-secrets}.ejson"
        if [ -f "$EJSON" ]; then
          echo "Loading secrets: $EJSON"
          eval "$(ejson2env "$EJSON")"
        else
          echo "Secrets file not found: $EJSON"
        fi
      }

      # load default secrets at shell startup (only if the secrets file exists)
      if [ -f "$HOME/.secrets.d/secrets.ejson" ]; then
        secrets
      fi
    '';
  };

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
  programs.starship.package = starshipPackage;
  programs.starship.settings = {
    # Use the git executable for branch detection so repositories that use
    # Git's reftable backend report the real branch instead of "HEAD".
    git_branch.use_git_executable = true;

    # Disable slow modules
    git_status.disabled = true;

    # Disable noisy modules that aren't actionable day-to-day
    gcloud.disabled = true;
    nix_shell.disabled = true;
    package.disabled = true;
  };
}
