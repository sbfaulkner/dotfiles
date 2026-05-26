{ pkgs, lib, isWork, ... }:

let
  starshipVersion = "1.25.1";
  # Starship 1.25 adds git_branch.use_git_executable, which is needed for
  # repositories that use Git's reftable backend (e.g. Shopify's world repo).
  systemStr = if builtins ? currentSystem then builtins.currentSystem else pkgs.system;
  isAarch = builtins.substring 0 7 systemStr == "aarch64";
  starshipTarget = if isAarch then "aarch64-apple-darwin" else "x86_64-apple-darwin";
  starshipHash = if isAarch
    then "sha256-/ok0mYmKwYE8FccucpP/tTdZBjZ5S3/nPhMmR7V/lW8="
    else "sha256-9PxP5zUkc5oeAI1xobQlHSIpXNlDZjw+Chmm2qCKdz4=";
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
      reflake = if isWork
        then "home-manager switch --flake ~/src/github.com/sbfaulkner/dotfiles#work"
        else "sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner";
    } // lib.optionalAttrs isWork {
      gcurl = ''curl -s --header "Authorization: Bearer $(gcloud auth print-access-token)"'';
      doh = "warp-cli mode doh";
      warp = "warp-cli mode warp+doh";
      kngx = "kubectl ingress-nginx";
    };

    initContent = ''
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
          eval $(ejson2env "$EJSON")
        else
          echo "Secrets file not found: $EJSON"
        fi
      }

      # load default secrets at shell startup (only if the secrets file exists)
      if [ -f "$HOME/.secrets.d/secrets.ejson" ]; then
        secrets
      fi
    '' + lib.optionalString isWork ''

      # --- Work-only below ---

      # Silence shadowenv activation messages (version info already in prompt)
      export SHADOWENV_SILENT=1

      # Homebrew shellenv (must come before work toolchain init)
      [[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

      # Work toolchain init (PATH, per-directory env hooks, etc.)
      [[ -x $HOME/.local/state/tec/profiles/base/current/global/init ]] && \
        eval "$($HOME/.local/state/tec/profiles/base/current/global/init zsh)"

      # dev.sh (may still be needed by some workflows)
      [ -f /opt/dev/dev.sh ] && source /opt/dev/dev.sh

      # chruby lazy-load (may still be needed for some projects)
      [[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }

      # cloudplatform — kubernetes config and workflow helpers
      export KUBECONFIG=''${KUBECONFIG:+$KUBECONFIG:}$HOME/.kube/config:$HOME/.kube/config.shopify.cloudplatform
      for file in $HOME/src/github.com/Shopify/cloudplatform/workflow-utils/*.bash; do source ''${file}; done
      kubectl-short-aliases

      # Graphite completions
      eval "$(gt completion)"
    '';
  };

  # PATH additions
  home.sessionPath = [
    "$HOME/scripts"
    "$HOME/bin"
  ] ++ lib.optionals isWork [
    "$HOME/src/github.com/Shopify/edge-infrastructure/scripts"
    "$HOME/.krew/bin"
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
