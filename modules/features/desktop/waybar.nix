{ self, ... }: {
  flake.nixosModules.waybar = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureWaybar
    ];
  };

  perSystem = { pkgs, ... }:
    let
      waybarConfig = (pkgs.formats.json { }).generate "waybar-config.json" {
        layer = "top";
        position = "top";
        height = 28;
        spacing = 4;

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

        tray.spacing = 8;
      };

      waybarStyle = pkgs.writeText "waybar-style.css" ''
        * {
          font-family: monospace;
          font-size: 13px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background: rgba(30, 30, 46, 0.93);
          color: #cdd6f4;
        }

        #workspaces button {
          padding: 0 6px;
          color: #cdd6f4;
          background: transparent;
        }

        #workspaces button.active {
          color: #1e1e2e;
          background: #89b4fa;
        }

        #workspaces button.urgent {
          color: #1e1e2e;
          background: #fab387;
        }

        #clock, #pulseaudio, #network, #cpu, #memory, #tray {
          padding: 0 10px;
        }
      '';
    in
    {
      packages.apertureWaybar = pkgs.symlinkJoin {
        name = "aperture-waybar";
        paths = [ pkgs.waybar ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/waybar \
            --add-flags "-c ${waybarConfig} -s ${waybarStyle}"
        '';
        meta.mainProgram = "waybar";
      };
    };
}