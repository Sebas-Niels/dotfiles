{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowedUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        vmware = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs system; };
          modules = [
           ./hosts/vmware

          ];
        };

        workmachine = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs; };
          modules = [
            ./hosts/workmachine/configuration.nix
          ];
        };
      };

    };
}
