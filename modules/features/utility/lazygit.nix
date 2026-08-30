{ self, inputs, ... }: {

  flake.nixosModules.lazygit = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaLazygit
    ];
  };

  perSystem = { pkgs, ... }: {

    packages.lambdaLazygit =
      let
        configFile = (pkgs.formats.yaml { }).generate "lazygit-config.yml" {
          gui.mouseEvents = false;
        };
      in
      pkgs.symlinkJoin {
        name = "lazygit";
        paths = [ pkgs.lazygit ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/lazygit --set LG_CONFIG_FILE ${configFile}
        '';
      };
  };
}