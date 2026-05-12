# hosts/work.nix — work-specific overrides for standalone home-manager
#
# Phase 1: disable shell management and skip packages the work toolchain
# already provides. Remove these overrides as we progress through the
# migration phases.
{ pkgs, lib, ... }:

{
  # Don't manage zsh yet — existing .zshrc has critical work tooling hooks.
  programs.zsh.enable = lib.mkForce false;

  # Don't install starship yet — depends on zsh being managed.
  programs.starship.enable = lib.mkForce false;

  # Don't install try yet — already set up in existing .zshrc.
  programs.try.enable = lib.mkForce false;

  # Don't install 1Password shell plugins yet.
  programs._1password-shell-plugins.enable = lib.mkForce false;

  # Don't enable direnv yet — work uses per-directory env tool for per-project env.
  programs.direnv.enable = lib.mkForce false;

  # Exclude packages the work toolchain already provides.
  home.packages = lib.mkForce (with pkgs; [
    # Add work-only packages here (things work toolchain doesn't provide).
    # e.g. mtr
  ]);
}
