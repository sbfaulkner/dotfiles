# hosts/work.nix — work-specific overrides for standalone home-manager
{ pkgs, lib, config, ... }:

{
  imports = [
    ./work-shell.nix
  ];
  # Don't enable direnv — work uses a different per-directory env tool.
  programs.direnv.enable = lib.mkForce false;

  # Exclude packages the work toolchain already provides, but keep
  # sessionVariablesPackage so hm-session-vars.sh ends up in the profile
  # (sourced by .zshenv). Keep ejson/ejson2env because the shared
  # secrets function depends on them before Homebrew/work init runs.
  home.packages = lib.mkForce [
    config.home.sessionVariablesPackage
    pkgs.ejson
    pkgs.ejson2env
    pkgs.home-manager  # needed so `reflake` alias can find home-manager
    config.programs.starship.package  # prompt CLI (explain, toggle, etc.)
  ];
}
