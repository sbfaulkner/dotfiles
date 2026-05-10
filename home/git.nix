{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name = "S. Brent Faulkner";
      user.email = "sbfaulkner@gmail.com";
      core.editor = "code --wait";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
