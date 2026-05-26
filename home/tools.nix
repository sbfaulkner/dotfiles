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
  ghHash = if isAarch
    then "sha256-4rVFCcMMaVwsg1yJxZKs5GWdEqculWamP0zWjjf9wXk="
    else "sha256-FfnabysqjqK6XUCOFm8EL2IVHqrv5tt6ptscoan3YM0=";
  ghSrc = pkgs.fetchzip {
    url = ghUrl;
    hash = ghHash;
  };
  # Directory inside the zip: gh_<version>_<asset>/
  # The release zips place the gh binary at bin/gh at the top level, so copy from there.
  ghBin = pkgs.runCommand "gh-${ghVersion}" { } ''
    mkdir -p $out/bin
    cp ${ghSrc}/bin/gh $out/bin/gh
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
