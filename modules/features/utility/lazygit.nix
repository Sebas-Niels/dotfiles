{ self, inputs, ... }: {

  flake.nixosModules.lazygit = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaLazygit
    ];
  };

  perSystem = { pkgs, ... }: {

    packages.lambdaLazygit = inputs.wrapper-modules.wrappers.lazygit.wrap {
      inherit pkgs;
      settings = {
        gui.mouseEvents = false;
      };
    };
  };
}