{ bash, lib, nodejs_22, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  version = "placeholder";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/pi-coding-agent"

    cat > "$out/share/pi-coding-agent/placeholder.js" <<'EOF'
const arg = process.argv[2] ?? "";

switch (arg) {
  case "--version":
  case "-v":
  case "version":
    console.log("pi-coding-agent placeholder");
    break;
  case "--node-version":
    console.log(process.version);
    break;
  case "--node-path":
    console.log(process.execPath);
    break;
  default:
    console.log("pi-coding-agent placeholder");
    console.error("This package verifies dotfiles flake wiring and its package-private Node runtime; it does not run Pi yet.");
    break;
}
EOF

    cat > "$out/bin/pi" <<EOF
#!${bash}/bin/bash
set -euo pipefail
exec ${nodejs_22}/bin/node "$out/share/pi-coding-agent/placeholder.js" "\$@"
EOF
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
