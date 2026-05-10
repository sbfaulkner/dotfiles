{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ejson    # encrypted secrets management
    fd       # fast alternative to find
    gh       # GitHub CLI
    nodejs   # javascript runtime
    pnpm     # fast, disk-efficient package manager (used at work too)
  ];

  # Set pnpm's global package directory.
  # Global binaries (e.g. pi) land directly in $PNPM_HOME.
  home.sessionVariables = {
    LESS = "-RF";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  # Add pnpm global bin to PATH so installed tools (e.g. pi) are found.
  home.sessionPath = [
    "$HOME/.local/share/pnpm"
  ];
}
