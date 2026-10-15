{ self, ... }: {
  flake.nixosModules.swww = { pkgs, ... }: {
    environment.systemPackages = [
      # swww has been renamed to awww upstream; this gives `awww img ...` for switching wallpapers
      pkgs.awww
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureSwww
    ];
  };

  perSystem = { pkgs, self', ... }: {
    # Starts the daemon, waits for it to accept requests, then sets the current theme's
    # wallpaper (each theme brings its own, see theme-menu.nix)
    packages.apertureSwww = pkgs.writeShellApplication {
      name = "aperture-swww";
      runtimeInputs = [ pkgs.awww self'.packages.apertureTheme ];
      text = ''
        aperture-theme init
        awww-daemon &
        until awww query >/dev/null 2>&1; do sleep 0.1; done
        awww img --transition-type grow "$(aperture-theme wallpaper)"
        wait
      '';
    };
  };
}
