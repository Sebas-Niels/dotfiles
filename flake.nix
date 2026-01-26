{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    #noctalia = {
    #  url = "github:noctalia-dev/noctalia-shell";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = { self, nixpkgs, ... } @ inputs:
{
  nixosConfigurations = {
    lambda = nixpkgs.lib.nixosSystem {

      specialArgs = { inherit inputs; };

      modules = [
        ./hosts/lambda
      ];
    };

    "vmware-setup" = nixpkgs.lib.nixosSystem {

      specialArgs = { inherit inputs; };

      modules = [
        ./hosts/vmware-setup/configuration.nix
      ];
    };
  };
};

}
