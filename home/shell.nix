{ pkgs, ... }:

{
  # home-manager generates ~/.zshrc — oh-my-zsh is gone.
  programs.zsh.enable = true;

  # Starship replaces spaceship. home-manager wires it into zsh automatically.
  programs.starship.enable = true;
}
