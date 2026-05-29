{ pkgs, config, ... }:

let
  ghVersion = "2.92.0";
  # Always use the macOS arm64 (Apple Silicon) gh release.
  armName = "macOS_arm64";
  ghAssetName = "gh_${ghVersion}_${armName}.zip";
  ghUrl = "https://github.com/cli/cli/releases/download/v${ghVersion}/${ghAssetName}";
  ghHash = "sha256-4rVFCcMMaVwsg1yJxZKs5GWdEqculWamP0zWjjf9wXk=";
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
    glow       # Markdown renderer used by lessfilter
    jq         # JSON query/filter CLI
    nodejs     # javascript runtime
    pnpm       # fast, disk-efficient package manager (used at work too)
    ripgrep    # fast recursive grep (rg)
    yq-go      # YAML query/pretty-printer used by lessfilter
  ];

  # direnv + nix-direnv: automatically activate per-project flake dev shells
  # on `cd`. Add `use flake` to a project's .envrc and `direnv allow`.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Set pnpm's global package directory.
  # Global binaries installed with `pnpm add -g` land directly in $PNPM_HOME.
  home.sessionVariables = {
    EDITOR = "code --wait";
    LESS = "-RFX";
    LESSOPEN = "|${config.xdg.configHome}/dotfiles/lessfilter %s";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  # Render common structured docs/configs before handing them to less.
  xdg.configFile."dotfiles/lessfilter" = {
    source = ./dotfiles/lessfilter;
    executable = true;
  };

  # Add pnpm global bin to PATH so pnpm-installed tools are found.
  home.sessionPath = [
    "$HOME/.local/share/pnpm"
  ];
}
