# hosts/personal.nix — personal-machine home-manager overrides
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ../pkgs/pi-coding-agent.nix { })
  ];

  programs.zsh.shellAliases.reflake = "sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner";

  programs.git.settings.user = {
    name = "S. Brent Faulkner";
    email = "sbfaulkner@gmail.com";
  };

  # Pi — personal model/provider defaults.
  programs.pi.settings = {
    defaultProvider = "github-copilot";
    defaultModel = "gpt-5-mini";
  };

  # Run reflake check for interactive shells; run in foreground so prompts work
  programs.zsh.initContent = ''
    if [[ -x $HOME/.config/dotfiles/check-reflake ]] && [[ -o interactive ]]; then
      # Run synchronously so the user can be prompted and choose to reflake now.
      "$HOME/.config/dotfiles/check-reflake" || true
    fi
  '';
}
