# hosts/personal.nix — personal-machine home-manager overrides
{ ... }:

{
  programs.zsh.shellAliases.reflake = "sudo darwin-rebuild switch --flake ~/src/github.com/sbfaulkner/dotfiles#sbfaulkner";
}
