{ bash, lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  version = "placeholder";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cat > "$out/bin/pi" <<'EOF'
#!@bash@/bin/bash
set -euo pipefail

case "''${1-}" in
  --version|-v|version)
    printf '%s\n' "pi-coding-agent placeholder"
    ;;
  *)
    printf '%s\n' "pi-coding-agent placeholder"
    printf '%s\n' "This package only verifies dotfiles flake wiring; it does not run Pi yet." >&2
    ;;
esac
EOF
    substituteInPlace "$out/bin/pi" --replace-fail @bash@ ${bash}
    chmod +x "$out/bin/pi"

    runHook postInstall
  '';

  meta = {
    description = "Placeholder package for the Pi coding agent";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.darwin;
  };
}
