{ pkgs, isWork, ... }:

{
  programs.zsh = {
    enable = true;

    # Shortcuts for cd — checks these directories when a path isn't found locally.
    cdpath = [
      "$HOME/src/github.com/sbfaulkner"
      "$HOME/src/github.com"
      "$HOME/src"
      "$HOME"
    ];

    shellAliases = {
      a = "alias";
      h = "history";
      reflake = if isWork
        then "home-manager switch --flake ~/src/github.com/sbfaulkner/dotfiles#work"
        else "sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner";
    };
  };

  # try — experiment directory manager
  programs.try = {
    enable = true;
    path = "~/src/tries";
  };

  # 1Password shell plugins — installs op from Nix and enables credential
  # injection for specified CLIs. Replaces the Homebrew 1password-cli cask.
  programs._1password-shell-plugins = {
    enable = true;
    # plugins = with pkgs; [ gh ];  # disabled: causes pi sessions to hang (TODO: figure out how to make 1Password agent available in pi sessions)
  };

  # Starship replaces spaceship. home-manager wires it into zsh automatically.
  programs.starship.enable = true;
}
