# home/pi.nix — pi coding agent configuration
#
# Manages the pi settings seed and ensures the personal pi-extensions
# package is cloned and registered.  Host-specific overrides (model,
# provider, extra packages) live in hosts/personal.nix and hosts/work.nix.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pi;

  piExtensionsRepo = "https://github.com/sbfaulkner/pi-extensions.git";
  piExtensionsDir = "$HOME/src/github.com/sbfaulkner/pi-extensions";

  # The package entry for pi-extensions as it appears in settings.json.
  piExtensionsPackage = {
    source = "~/src/github.com/sbfaulkner/pi-extensions";
  };

  jq = "${pkgs.jq}/bin/jq";
  git = "${pkgs.gitMinimal}/bin/git";

  # Build the seed settings.json from shared + host-specific attrs.
  seedJson = builtins.toJSON (
    {
      theme = "light";
      defaultThinkingLevel = "medium";

      # pi-extensions is always present as a package
      packages = [ piExtensionsPackage ];
    }
    // cfg.settings
  );
in
{
  options.programs.pi = {
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Host-specific pi settings merged on top of the shared base.
        Used only when seeding a new settings.json (seed-only, not
        overwritten on subsequent activations).
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional pi packages to install via `pi install` on every
        activation.  Use for git-hosted packages that should be cloned
        into ~/.pi/agent/git/ (e.g. shop-pi-fy, pi-autoresearch).
        Idempotent — already-installed packages are skipped.
      '';
    };
  };

  config = {
    # Clone pi-extensions if the checkout is missing.
    home.activation.clonePiExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      pi_ext="${piExtensionsDir}"
      if [ ! -d "$pi_ext/.git" ]; then
        run mkdir -p "$(dirname "$pi_ext")"
        run ${git} clone ${piExtensionsRepo} "$pi_ext"
      fi
    '';

    # Seed settings.json if it does not exist yet.
    home.activation.seedPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" "clonePiExtensions" ] ''
      pi_settings="$HOME/.pi/agent/settings.json"
      if [ ! -f "$pi_settings" ]; then
        run mkdir -p "$(dirname "$pi_settings")"
        cat > "$pi_settings" << 'SEED_EOF'
${seedJson}
SEED_EOF
        verboseEcho "Seeded pi settings at $pi_settings"
      fi
    '';

    # Ensure pi-extensions is registered as a package in an existing
    # settings.json that may predate this module.
    home.activation.ensurePiExtensionsPackage = lib.hm.dag.entryAfter [ "writeBoundary" "seedPiSettings" ] ''
      pi_settings="$HOME/.pi/agent/settings.json"
      if [ -f "$pi_settings" ]; then
        has_pkg=$(${jq} -r '
          .packages // [] | map(
            if type == "object" then .source else . end
          ) | any(test("pi-extensions"))
        ' "$pi_settings")

        if [ "$has_pkg" != "true" ]; then
          verboseEcho "Adding pi-extensions package to $pi_settings"
          ${jq} '.packages = (.packages // []) + [${builtins.toJSON piExtensionsPackage}]' \
            "$pi_settings" > "$pi_settings.tmp" \
            && run mv "$pi_settings.tmp" "$pi_settings"
        fi
      fi
    '';

    # Install extra git-hosted packages via `pi install` (idempotent).
    home.activation.installPiPackages = lib.hm.dag.entryAfter [ "writeBoundary" "seedPiSettings" ] (
      lib.concatMapStringsSep "\n" (pkg: ''
        verboseEcho "Ensuring pi package: ${pkg}"
        run pi install ${pkg} 2>/dev/null || verboseEcho "pi install ${pkg} skipped or failed"
      '') cfg.extraPackages
    );
  };
}
