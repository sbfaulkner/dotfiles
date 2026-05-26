{ pkgs, ... }:

{
  imports = [
    ./git.nix
    ./shell.nix
    ./tools.nix
  ];

  # Suppress unread Home Manager news notices during rebuilds.
  # News remains available manually via `home-manager news`.
  news.display = "silent";

  # Required: tells home-manager who you are and where you live.
  home.username = "sbfaulkner";
  home.homeDirectory = "/Users/sbfaulkner";

  # Required: the version of home-manager options this config was written for.
  # Like system.stateVersion — set once and leave it.
  home.stateVersion = "24.11";
}
