{ pkgs, lib, isWork, ... }:

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
    '' + lib.optionalString isWork ''

      # --- Work-only below ---

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
  programs.starship.settings = {
    # Disable noisy modules that aren't actionable day-to-day
    gcloud.disabled = true;
    nix_shell.disabled = true;
    package.disabled = true;
  };
}
