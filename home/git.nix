{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "S. Brent Faulkner";
    userEmail = "sbfaulkner@gmail.com";

    extraConfig = {
      core.editor = "code --wait";
      init.defaultBranch = "main";
      pull.rebase = true;
    };

    # Global gitignore — applies to every repo without touching individual .gitignore files.
    ignores = [
      ".direnv/"   # nix-direnv cache
      ".DS_Store"  # macOS filesystem metadata
    ];
  };
}
