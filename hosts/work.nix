# hosts/work.nix — work-specific overrides for standalone home-manager
{ pkgs, lib, config, ... }:

{
  imports = [
    ./work-shell.nix
  ];
  # Don't enable direnv — work uses a different per-directory env tool.
  programs.direnv.enable = lib.mkForce false;

  # Exclude packages the work toolchain already provides, but keep
  # sessionVariablesPackage so hm-session-vars.sh ends up in the profile
  # (sourced by .zshenv). Keep ejson/ejson2env because the shared
  # secrets function depends on them before Homebrew/work init runs.
  # Pi — work model/provider defaults and extra packages.
  programs.pi.settings = {
    defaultProvider = "anthropic-250k-prefer-using-this-one";
    defaultModel = "claude-opus-4-6";
    enabledModels = [
      "anthropic/claude-haiku-4-5"
      "anthropic-250k-prefer-using-this-one/claude-sonnet-4-6"
      "anthropic-250k-prefer-using-this-one/claude-opus-4-6"
      "openai/gpt-5.4"
      "openai/gpt-5.4-mini"
      "openai/gpt-5.4-nano"
      "anthropic-250k-prefer-using-this-one/claude-opus-4-7"
      "openai/gpt-5.5"
    ];
    extensions = [
      "-extensions/vim-mode/index.ts"
      "+extensions/chrome-devtools/index.ts"
      "+extensions/web-search/index.ts"
      "-extensions/rtk-rewrite/index.ts"
    ];
    skills = [
      "+skills/agent-world/SKILL.md"
      "-skills/talent-shopify/SKILL.md"
      "-skills/graphite/SKILL.md"
    ];
  };
  programs.pi.extraPackages = [
    "https://github.com/shopify-playground/shop-pi-fy"
    "https://github.com/davebcn87/pi-autoresearch"
    "https://github.com/shopify-playground/pi-usage-awareness"
  ];

  home.packages = lib.mkForce [
    config.home.sessionVariablesPackage
    pkgs.ejson
    pkgs.ejson2env
    pkgs.glow_1_5_1  # Markdown previews in less; pinned for ANSI compatibility
    pkgs.home-manager  # needed so `reflake` alias can find home-manager
    config.programs.starship.package  # prompt CLI (explain, toggle, etc.)
    pkgs.herdr
  ];

  # cmux — install via Homebrew cask on work machines.
  # The personal machine manages cmux declaratively through nix-darwin's
  # homebrew module (see darwin.nix). Work uses standalone home-manager
  # (no nix-darwin), so we install idempotently via an activation script.
  home.activation.installCmux = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v brew >/dev/null 2>&1; then
      brew tap manaflow-ai/cmux 2>/dev/null || true
      brew install --cask cmux 2>/dev/null || true
    fi
  '';
}
