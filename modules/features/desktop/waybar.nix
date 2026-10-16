{ self, ... }: {
  flake.nixosModules.waybar = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureWaybar
    ];
  };

  perSystem = { pkgs, lib, self', ... }:
    let
      waybarConfig = (pkgs.formats.json { }).generate "waybar-config.json" {
        layer = "top";
        position = "top";
        height = 44;
        spacing = 6;

        # mango exposes its tags over ext-workspace, not the dwl ipc protocol
        modules-left = [ "ext/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

        "ext/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-id = true;
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "{:%Y-%m-%d}";
        };

        pulseaudio = {
          format = "vol {volume}%";
          format-muted = "muted";
        };

        network = {
          format-wifi = "{essid} {signalStrength}%";
          format-ethernet = "eth";
          format-disconnected = "offline";
        };

        cpu.format = "cpu {usage}%";
        memory.format = "mem {percentage}%";

        tray.spacing = 12;
      };

      # Rendered once per theme by the theme menu (see theme-menu.nix)
      waybarStyle = t: ''
        * {
          font-family: monospace;
          font-size: 20px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background: ${t.rgba t.c.bg "0.93"};
          color: ${t.c.text};
        }

        #workspaces button {
          padding: 0 10px;
          color: ${t.c.text};
          background: transparent;
          transition: background-color 200ms ease, color 200ms ease;
        }

        #workspaces button:hover {
          background: ${t.c.surface};
        }

        #workspaces button.active {
          color: ${t.c.bg};
          background: ${t.c.accent};
        }

        #workspaces button.urgent {
          color: ${t.c.bg};
          background: ${t.c.yellow};
        }

        #clock, #pulseaudio, #network, #cpu, #memory, #tray {
          padding: 0 15px;
        }
      '';

      # nixos-rebuild doesn't restart anything started by the compositor, so waybar watches for a
      # switch itself: once the system's waybar is a different build, it hands over to that one.
      # The same check brings the bar back if it crashes.
      waybar = pkgs.writeShellScript "waybar" ''
        ${lib.getExe self'.packages.apertureTheme} init
        start_bar() {
          ${lib.getExe pkgs.waybar} -c ${waybarConfig} \
            -s "$HOME/.local/state/aperture-theme/current/waybar.css" "$@" &
          bar=$!
        }
        start_bar "$@"

        trap 'kill "$bar" 2>/dev/null' EXIT
        # This script is also named waybar, so the theme menu's `pkill -USR2 -x waybar` reaches it
        # too; without a handler that would kill it, and the EXIT trap would take the bar with it.
        # A no-op handler keeps it alive (an empty trap would mark USR2 ignored, which exec passes on).
        trap ':' USR2

        self=$(${pkgs.coreutils}/bin/readlink -f "$0")
        while :; do
          ${pkgs.coreutils}/bin/sleep 3
          if ! kill -0 "$bar" 2>/dev/null; then
            status=0
            wait "$bar" || status=$?
            # A clean exit or the compositor going away means it should stay down
            [ "$status" -eq 0 ] && exit
            [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || exit
            start_bar "$@"
            continue
          fi
          installed=$(${pkgs.coreutils}/bin/readlink -f /run/current-system/sw/bin/waybar) || continue
          if [ "$installed" != "$self" ]; then
            kill "$bar"
            wait "$bar" 2>/dev/null
            trap - EXIT
            exec /run/current-system/sw/bin/waybar "$@"
          fi
        done
      '';
    in
    {
      apertureTheme.targets."waybar.css" = waybarStyle;

      packages.apertureWaybar = pkgs.symlinkJoin {
        name = "aperture-waybar";
        paths = [ pkgs.waybar ];
        postBuild = ''
          rm $out/bin/waybar
          ln -s ${waybar} $out/bin/waybar
        '';
        meta.mainProgram = "waybar";
      };
    };
}
