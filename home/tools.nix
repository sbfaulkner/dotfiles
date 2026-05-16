{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ejson      # encrypted secrets management
    fastfetch  # system info summary
    fd         # fast alternative to find
    gh         # GitHub CLI
    nodejs     # javascript runtime
    pnpm       # fast, disk-efficient package manager (used at work too)
    starship   # prompt — also managed by programs.starship, but this puts the CLI on PATH
  ];

  # direnv + nix-direnv: automatically activate per-project flake dev shells
  # on `cd`. Add `use flake` to a project's .envrc and `direnv allow`.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Set pnpm's global package directory.
  # Global binaries (e.g. pi) land directly in $PNPM_HOME.
  home.sessionVariables = {
    EDITOR = "code --wait";
    LESS = "-RF";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  # Add pnpm global bin to PATH so installed tools (e.g. pi) are found.
  # Add cargo/rustup bin so Rust toolchain is available in non-interactive shells (e.g. pi agent).
  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.cargo/bin"
  ];
}
