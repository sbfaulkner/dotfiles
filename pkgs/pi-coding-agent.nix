{
  fd,
  fetchurl,
  gitMinimal,
  lib,
  makeWrapper,
  openssh,
  ripgrep,
  stdenvNoCC,
}:

let
  runtimePath = lib.makeBinPath [
    fd
    gitMinimal
    openssh
    ripgrep
  ];
in
stdenvNoCC.mkDerivation rec {
  pname = "pi-coding-agent";
  version = "0.82.0";

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-darwin-arm64.tar.gz";
    hash = "sha256-YgXevQBx/1bXZeDulB8If5oY0fbC996he9yPl/88+cE=";
  };

  sourceRoot = "pi";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/pi"
    cp -R . "$out/lib/pi/"

    makeWrapper "$out/lib/pi/pi" "$out/bin/pi" \
      --set PI_PACKAGE_DIR "$out/lib/pi" \
      --suffix PATH : "${runtimePath}"

    runHook postInstall
  '';

  meta = {
    description = "Pi coding agent CLI";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.darwin;
  };
}
