{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ejson    # encrypted secrets management
    fd       # fast alternative to find
    gh       # GitHub CLI
    nodejs   # javascript runtime (+ npm)
  ];

  # Set npm's global package prefix to a user-owned directory.
  # Without this, `npm install -g` would try to write into the Nix store (read-only).
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };
}
