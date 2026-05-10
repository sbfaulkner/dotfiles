{
  description = "sbfaulkner's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-community/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {

    # Personal machine — Intel Mac, nix-darwin + home-manager
    darwinConfigurations.sbfaulkner = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        { nixpkgs.hostPlatform = "x86_64-darwin"; }
        ./darwin.nix
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sbfaulkner = import ./home;
        }
      ];
    };

    # Work machine — Apple Silicon, standalone home-manager on top of work toolchain
    # Uncomment when ready to set up
    # homeConfigurations.work = inputs.home-manager.lib.homeManagerConfiguration {
    #   pkgs = inputs.nixpkgs.legacyPackages."aarch64-darwin";
    #   modules = [ ./home ];
    # };

  };
}
