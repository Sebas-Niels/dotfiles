{ self, inputs, ... }: {
  flake.nixosConfigurations.lambda = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.lambdaConfiguration
    ];
  };
}
