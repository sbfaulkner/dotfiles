# hosts/personal.nix — personal-machine home-manager overrides
{ ... }:

{
  programs.zsh.shellAliases.reflake = "sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner";

  programs.git.settings.user = {
    name = "S. Brent Faulkner";
    email = "sbfaulkner@gmail.com";
  };
}
