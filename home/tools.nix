{ pkgs, ... }:

let
  ghVersion = "2.92.0";
  ghUrl = "https://github.com/cli/cli/releases/download/v${ghVersion}/gh_${ghVersion}_macOS_amd64.zip";
  ghSha = "1w1akm8zmsl2lwsih00fkgqs18il83qzhyfsv8dhg48dmckv76xf"; # pinned via nix-prefetch-url
  ghSrc = pkgs.fetchzip {
    url = ghUrl;
    sha256 = ghSha;
  };
  ghBin = pkgs.runCommand "gh-${ghVersion}" { } ''
    mkdir -p $out/bin
    # zip layout: gh_<version>_macOS_amd64/bin/gh
    cp ${ghSrc}/gh_${ghVersion}_macOS_amd64/bin/gh $out/bin/gh
    chmod +x $out/bin/gh
  '';
in
{
  home.packages = with pkgs; [
    ejson      # encrypted secrets management
    ejson2env  # decrypt EJSON and export as env vars
    fastfetch  # system info summary
    fd         # fast alternative to find
    # Use pinned GitHub CLI release instead of the nixpkgs-provided package
    ghBin
    nodejs     # javascript runtime
    pnpm       # fast, disk-efficient package manager (used at work too)
    starship   # prompt — also managed by programs.starship, but this puts the CLI on PATH
  ];

  # direnv + nix-direnv: automatically activate per-project flake dev shells
  # on `cd`. Add `use flake` to a project's .envrc and `direnv allow`.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Set pnpm's global package directory.
  # Global binaries (e.g. pi) land directly in $PNPM_HOME.
  home.sessionVariables = {
    EDITOR = "code --wait";
    LESS = "-RF";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  # Add pnpm global bin to PATH so installed tools (e.g. pi) are found.
  home.sessionPath = [
    "$HOME/.local/share/pnpm"
  ];
}
