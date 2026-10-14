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
          --add-flags "-c '#1e1e2e'"
      '';
      # For an image instead, put a wallpaper next to this file and use:
      #   --add-flags "-i ${./wallpaper.png} -m fill"
      meta.mainProgram = "swaybg";
    };
  };
}