{ self, ... }: {
  flake.nixosModules.swaybg = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureSwaybg
    ];
  };

  perSystem = { pkgs, ... }: {
    packages.apertureSwaybg = pkgs.symlinkJoin {
      name = "aperture-swaybg";
      paths = [ pkgs.swaybg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/swaybg \
          --add-flags "-i ${./wallpaper.jpg} -m fill"
      '';
      meta.mainProgram = "swaybg";
    };
  };
}