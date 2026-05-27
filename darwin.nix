{ pkgs, lib, ... }:

{
  # Allow packages with unfree licenses (e.g. 1password-cli).
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password-cli"
    ];

  # Required by nix-darwin for options that apply to a specific user
  # (e.g. homebrew). Set to the user running darwin-rebuild.
  system.primaryUser = "sbfaulkner";

  # Homebrew — managed declaratively, casks only.
  # CLI tools belong in home-manager (home/tools.nix) instead.
  homebrew = {
    enable = true;
    casks = [
      "godot"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall"; # remove casks not listed here
    };
  };

  # Tell nix-darwin about the user so home-manager can find the home directory.
  users.users.sbfaulkner.home = "/Users/sbfaulkner";

  # The stateVersion marks when this config was first created.
  # Set it once on first install and never change it.
  system.stateVersion = 5;

  # Determinate Nix manages the Nix daemon and /etc/nix/nix.conf.
  # Disable nix-darwin's native Nix management to avoid conflicting daemons.
  nix.enable = false;
}
