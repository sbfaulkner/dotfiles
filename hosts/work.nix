# hosts/work.nix — work-specific overrides for standalone home-manager
#
# Phase 1: disable shell management and skip packages the work toolchain
# already provides. Remove these overrides as we progress through the
# migration phases.
{ pkgs, lib, ... }:

{
  # Don't manage zsh yet — existing .zshrc has critical hooks for work tooling.
  programs.zsh.enable = lib.mkForce false;

  # Don't install starship yet — depends on zsh being managed.
  programs.starship.enable = lib.mkForce false;

  # Don't install try yet — already set up in existing .zshrc.
  programs.try.enable = lib.mkForce false;

  # Don't install 1Password shell plugins yet.
  programs._1password-shell-plugins.enable = lib.mkForce false;

  # Don't enable direnv yet — work uses a different per-directory env tool.
  programs.direnv.enable = lib.mkForce false;

  # Exclude packages the work toolchain already provides.
  home.packages = lib.mkForce (with pkgs; [
    # Add work-only packages here (things not provided by the work toolchain).
    # e.g. mtr
  ]);
}
