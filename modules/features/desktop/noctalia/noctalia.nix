{ self, inputs, ... }: {

  flake.nixosModules.noctalia = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureNoctalia
    ];
  };

  perSystem = { pkgs, system, ... }: {

    _module.args.pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        noctalia-qs = prev.noctalia-qs.override { withCrashReporter = false; };
      })
    ];
  };

    packages.apertureNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      settings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;
    };
  };
}
