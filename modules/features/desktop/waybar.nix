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

        modules-left = [ "dwl/tags" "dwl/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

        "dwl/tags" = {
          num-tags = 9;
        };

        "dwl/window" = {
          max-length = 60;
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

        #tags button {
          padding: 0 6px;
          color: #6c7086;
          background: transparent;
        }

        #tags button.occupied {
          color: #cdd6f4;
        }

        #tags button.focused {
          color: #1e1e2e;
          background: #89b4fa;
        }

        #tags button.urgent {
          color: #1e1e2e;
          background: #fab387;
        }

        #window, #clock, #pulseaudio, #network, #cpu, #memory, #tray {
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