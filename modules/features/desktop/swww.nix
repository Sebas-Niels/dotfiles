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
    # wallpaper (each theme brings its own, see theme-menu.nix). The daemon has panicked
    # when mango reloads its config, so it is brought back (without the transition) if it
    # dies; this script just sits in `wait` meanwhile, so the loop costs nothing.
    packages.apertureSwww = pkgs.writeShellApplication {
      name = "aperture-swww";
      runtimeInputs = [ pkgs.awww self'.packages.apertureTheme ];
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

          # A clean exit (`awww kill`) or the compositor going away means it should stay down
          [ "$status" -eq 0 ] && break
          [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || break
          transition=none
          sleep 1
        done
      '';
    };
  };
}
