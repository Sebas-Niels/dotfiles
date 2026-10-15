{ self, ... }: {
  flake.nixosModules.swww = { pkgs, ... }: {
    environment.systemPackages = [
      # swww has been renamed to awww upstream; this gives `awww img ...` for switching wallpapers
      pkgs.awww
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureSwww
    ];
  };

  perSystem = { pkgs, ... }: {
    # Starts the daemon, waits for it to accept requests, then sets the wallpaper
    packages.apertureSwww = pkgs.writeShellApplication {
      name = "aperture-swww";
      runtimeInputs = [ pkgs.awww ];
      text = ''
        awww-daemon &
        until awww query >/dev/null 2>&1; do sleep 0.1; done
        awww img --transition-type grow ${./wallpaper.png}
        wait
      '';
    };
  };
}
