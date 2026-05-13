# hosts/work.nix — work-specific overrides for standalone home-manager
#
# Phase 2: zsh is now managed. Packages and direnv still disabled
# (work toolchain provides them). Remove overrides as we progress.
{ pkgs, lib, config, ... }:

{
  # Don't enable direnv — work uses a different per-directory env tool.
  programs.direnv.enable = lib.mkForce false;

  # Exclude packages the work toolchain already provides, but keep
  # sessionVariablesPackage so hm-session-vars.sh ends up in the profile
  # (sourced by .zshenv).
  home.packages = lib.mkForce [
    config.home.sessionVariablesPackage
    pkgs.home-manager  # needed so `reflake` alias can find home-manager
  ];
}
