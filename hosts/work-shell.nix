# hosts/work-shell.nix — work-specific zsh aliases, PATH, and init
{ lib, ... }:

{
  programs.zsh.shellAliases = {
    reflake = "home-manager switch --flake ~/src/github.com/sbfaulkner/dotfiles#work";
    gcurl = ''curl -s --header "Authorization: Bearer $(gcloud auth print-access-token)"'';
    doh = "warp-cli mode doh";
    warp = "warp-cli mode warp+doh";
    kngx = "kubectl ingress-nginx";
  };

  programs.zsh.initContent = lib.mkOrder 960 ''
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

  home.sessionPath = [
    "$HOME/src/github.com/Shopify/edge-infrastructure/scripts"
    "$HOME/.krew/bin"
  ];
}
