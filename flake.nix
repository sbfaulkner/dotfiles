{
  description = "sbfaulkner's dotfiles";

  inputs = {
    # Track nixpkgs-unstable for current darwin fixes while flake.lock pins
    # exact revisions. Keep nix-darwin and home-manager inputs in sync via
    # inputs.nixpkgs.follows below.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Glow 2.x currently emits ANSI sequences that less(1) does not preserve
    # reliably under LESSOPEN + -R. Keep Markdown previews on Glow 1.5.1.
    nixpkgs-glow.url = "github:NixOS/nixpkgs/nixos-24.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    try-cli = {
      url = "github:tobi/try-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      glowOverlay = final: _prev: {
        glow_1_5_1 = inputs.nixpkgs-glow.legacyPackages.${final.stdenv.hostPlatform.system}.glow;
      };

      pkgsFor = system: import inputs.nixpkgs {
        inherit system;
        overlays = [ glowOverlay inputs.herdr.overlays.default ];
      };
    in
    {

    packages.aarch64-darwin =
      let
        pkgs = pkgsFor "aarch64-darwin";
        piCodingAgent = pkgs.callPackage ./pkgs/pi-coding-agent.nix { };
      in
      {
        pi-coding-agent = piCodingAgent;
        default = piCodingAgent;
      };

    # Personal machine — Apple Silicon (aarch64), nix-darwin + home-manager
    darwinConfigurations.sbfaulkner = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.overlays = [ glowOverlay inputs.herdr.overlays.default ];
        }
        ./darwin.nix
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          home-manager.sharedModules = [
            ./hosts/personal.nix
            inputs._1password-shell-plugins.hmModules.default
            inputs.try-cli.homeModules.default
          ];
          home-manager.users.sbfaulkner = import ./home;
        }
      ];
    };

    # Work machine — Apple Silicon, standalone home-manager
    homeConfigurations.work = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor "aarch64-darwin";
      modules = [
        ./home
        ./hosts/work.nix
        inputs._1password-shell-plugins.hmModules.default
        inputs.try-cli.homeModules.default
      ];
    };

  };
}
