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
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-5-5";
    defaultThinkingLevel = "high";
    enabledModels = [
      "fireworks-300k/glm-5.2"
      "fireworks-300k/fireworks:accounts/fireworks/routers/glm-5p2-fast"
      "openai/gpt-5.6-terra"
      "openai/gpt-5.6-luna"
      "anthropic/claude-opus-5-5"
      "anthropic-250k-prefer-using-this-one/claude-fable-5-1"
      "anthropic-250k-prefer-using-this-one/claude-sonnet-5-5"
      "openai/gpt-6-sol"
      "openai/gpt-6-astra"
    ];
    skills = [
      "-skills/talent-shopify/SKILL.md"
      "-skills/agent-tools/SKILL.md"
      "-skills/gws-sheets/SKILL.md"
      "-skills/gws-shared/SKILL.md"
      "-skills/gws-gmail-triage/SKILL.md"
      "-skills/gws-gmail-read/SKILL.md"
      "-skills/gws-gmail/SKILL.md"
      "-skills/gws-drive-upload/SKILL.md"
      "-skills/gws-drive/SKILL.md"
      "-skills/gws-docs-write/SKILL.md"
      "-skills/gws-docs/SKILL.md"
      "-skills/gws-calendar-agenda/SKILL.md"
      "-skills/gws-calendar/SKILL.md"
    ];
    # One lean profile shared by terminal pi and bb's Pi threads. Replaces the
    # base packages list (attrset merge), so pi-extensions is repeated here.
    # Brain comes from bb's Brain plugin, not brain's pi extension.
    packages = [
      {
        source = "~/src/github.com/sbfaulkner/pi-extensions";
        extensions = [ "secrets/index.ts" ];
        skills = [
          "-skills/git-workflow/SKILL.md"
          "-skills/gws-docs-markdown/SKILL.md"
        ];
      }
      # Loads nothing; listed so `pi update` keeps the checkout current for
      # the web-search and world symlinks below.
      {
        source = "https://github.com/shopify-playground/shop-pi-fy";
        extensions = [ ];
        skills = [ ];
        prompts = [ ];
        themes = [ ];
      }
    ];
  };
  # `pi install` keeps an existing package entry's filters, so this only
  # ensures the checkout exists.
  programs.pi.extraPackages = [
    "https://github.com/shopify-playground/shop-pi-fy"
  ];

  # web-search and world from the shop-pi-fy checkout. Its manifest declares
  # only its /pkg manager, so these load as linked extensions, not through
  # package filters.
  home.activation.linkPiShopPiFyExtensions = lib.hm.dag.entryAfter [ "installPiPackages" ] ''
    shop_pi_fy="$HOME/.pi/agent/git/github.com/shopify-playground/shop-pi-fy"
    for ext in web-search world; do
      if [ -d "$shop_pi_fy/extensions/$ext" ]; then
        run mkdir -p "$HOME/.pi/agent/extensions"
        run ln -sfn "$shop_pi_fy/extensions/$ext" "$HOME/.pi/agent/extensions/$ext"
      fi
    done
  '';

  home.packages = lib.mkForce [
    config.home.sessionVariablesPackage
    pkgs.ejson
    pkgs.ejson2env
    pkgs.glow_1_5_1  # Markdown previews in less; pinned for ANSI compatibility
    pkgs.home-manager  # needed so `reflake` alias can find home-manager
    config.programs.starship.package  # prompt CLI (explain, toggle, etc.)
  ];
}
