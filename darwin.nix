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
      "1password"
      "ghostty"
      "godot"
      "google-chrome"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall"; # remove casks not listed here
      extraFlags = [ "--force" ];
    };
  };

  # Tell nix-darwin about the user so home-manager can find the home directory.
  users.users.sbfaulkner.home = "/Users/sbfaulkner";

  # Keep ejson private keys in ejson's standard keydir. Make it writable by the
  # primary user so `ejson keygen --write` works for shell-managed secrets.
  #
  # Also set HOMEBREW_ASK=0 so `brew bundle install --cleanup` runs non-
  # interactively; newer Homebrew requires --force/--force-cleanup or this env.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    # Make Homebrew non-interactive during activation
    export HOMEBREW_ASK=0

    mkdir -p /opt/ejson/keys
    chown sbfaulkner:staff /opt/ejson/keys
    chmod 0755 /opt/ejson/keys
  '';

  # The stateVersion marks when this config was first created.
  # Set it once on first install and never change it.
  system.stateVersion = 5;

  # Determinate Nix manages the Nix daemon and /etc/nix/nix.conf.
  # Disable nix-darwin's native Nix management to avoid conflicting daemons.
  nix.enable = false;
}
