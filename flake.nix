{
  description = "sbfaulkner's dotfiles";

  inputs = {
    # Track nixpkgs-unstable for current darwin fixes while flake.lock pins
    # exact revisions. Keep nix-darwin and home-manager inputs in sync via
    # inputs.nixpkgs.follows below.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
  };

  outputs = inputs: {

    # Personal machine — Apple Silicon (aarch64), nix-darwin + home-manager
    darwinConfigurations.sbfaulkner = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        { nixpkgs.hostPlatform = "aarch64-darwin"; }
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
      pkgs = inputs.nixpkgs.legacyPackages."aarch64-darwin";
      modules = [
        ./home
        ./hosts/work.nix
        inputs._1password-shell-plugins.hmModules.default
        inputs.try-cli.homeModules.default
      ];
    };

  };
}
