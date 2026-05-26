{ pkgs, ... }:

let
  ghVersion = "2.92.0";
  # Determine the system string in a robust way: prefer builtins.currentSystem when
  # available, otherwise fall back to pkgs.system (provided by the pkgs argument).
  systemStr = if builtins ? currentSystem then builtins.currentSystem else pkgs.system;
  # Detect current system (e.g. "x86_64-darwin" or "aarch64-darwin") and
  # choose the matching release asset and pinned sha.
  isAarch = builtins.substring 0 7 systemStr == "aarch64";
  amdName = "macOS_amd64";
  armName = "macOS_arm64";
  ghAssetName = if isAarch then "gh_${ghVersion}_${armName}.zip" else "gh_${ghVersion}_${amdName}.zip";
  ghUrl = "https://github.com/cli/cli/releases/download/v${ghVersion}/${ghAssetName}";
  ghSha = if isAarch then "01qx3z6d1j993c2806lrsd2nzwzwnbjpjl27j1jys5bxppv5875i" else "1kb0yyls276vlrxdprpgm8g1aqig0ipid3j0bnxa53ia5dpxmy8m";
  ghSrc = pkgs.fetchzip {
    url = ghUrl;
    sha256 = ghSha;
  };
  # Directory inside the zip: gh_<version>_<asset>/
  ghDir = if isAarch then "gh_${ghVersion}_${armName}" else "gh_${ghVersion}_${amdName}";
  ghBin = pkgs.runCommand "gh-${ghVersion}" { } ''
    mkdir -p $out/bin
    cp ${ghSrc}/${ghDir}/bin/gh $out/bin/gh
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
