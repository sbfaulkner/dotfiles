{ pkgs, ... }:

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

    # Content added to ~/.zshrc for interactive shells.
    initContent = ''
      # try — experiment directory manager
      eval "$(try init ~/src/tries)"

      # 1Password shell completion
      if (( $+commands[op] )); then
        eval "$(op completion zsh)"
        compdef _op op
      fi
    '';
  };

  # Starship replaces spaceship. home-manager wires it into zsh automatically.
  programs.starship.enable = true;
}
