{ pkgs, ... }:

{
  # The stateVersion marks when this config was first created.
  # Set it once on first install and never change it.
  system.stateVersion = 5;

  # Nix daemon configuration.
  # nix-darwin takes ownership of /etc/nix/nix.conf from here on.
  nix.settings = {
    experimental-features = "nix-command flakes";
    max-jobs = "auto";
    warn-dirty = false;
  };
}
