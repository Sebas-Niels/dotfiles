{ self, ... }: {
  flake.nixosModules.swww = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.awww
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureSwww
    ];
  };

  perSystem = { pkgs, self', ... }: {
    packages.apertureSwww = pkgs.writeShellApplication {
      name = "aperture-swww";
      runtimeInputs = [
        pkgs.awww
        self'.packages.apertureTheme
      ];
      text = ''
        aperture-theme init
        transition=grow
        while :; do
          awww-daemon &
          daemon=$!
          until awww query >/dev/null 2>&1; do
            kill -0 "$daemon" 2>/dev/null || break
            sleep 0.1
          done
          awww img --transition-type "$transition" "$(aperture-theme wallpaper)" || true
          status=0
          wait "$daemon" || status=$?

          [ "$status" -eq 0 ] && break
          [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || break
          transition=none
          sleep 1
        done
      '';
    };
  };
}
