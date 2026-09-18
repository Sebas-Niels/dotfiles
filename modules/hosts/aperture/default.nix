{ self, inputs, ... }: {
  flake.nixosConfigurations.aperture = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.apertureConfiguration
    ];
  };
}
