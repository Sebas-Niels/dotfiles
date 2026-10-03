{ self, inputs, ... }: {

  flake.nixosModules.noctalia = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureNoctalia
    ];
  };

  perSystem = { pkgs, system, ... }: {

    # TEMP: breakpad fails to build with GCC 16, disable crash reporter
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          noctalia-qs = prev.noctalia-qs.overrideAttrs (old: {
            buildInputs = builtins.filter
              (p: (p.pname or "") != "breakpad")
              (old.buildInputs or [ ]);
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [
              (prev.lib.cmakeBool "CRASH_REPORTER" false)
            ];
          });
        })
      ];
    };

    packages.apertureNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      settings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;
    };
  };
}