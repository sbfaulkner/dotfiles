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

  # Nix daemon configuration.
  # nix-darwin takes ownership of /etc/nix/nix.conf from here on.
  nix.settings = {
    experimental-features = "nix-command flakes";
    max-jobs = "auto";
    warn-dirty = false;
  };
}
