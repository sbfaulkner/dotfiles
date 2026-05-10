{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fd       # fast alternative to find
    gh       # GitHub CLI
    ejson    # encrypted secrets management
  ];
}
