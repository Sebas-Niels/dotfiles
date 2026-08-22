{ self, inputs, ... }: {

    flake.nixosModules.noctalia = { pkgs, ... }: {
        environment.systemPackages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaNoctalia
        ];
    };
    
    perSystem = { pkgs, ... }: {

        packages.lambdaNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
            inherit pkgs;
            settings =
                (builtins.fromJSON
                    (builtins.readFile ./noctalia.json)).settings;
        };
    };
}
