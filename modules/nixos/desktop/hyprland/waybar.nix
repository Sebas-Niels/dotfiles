{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;

        modules-left = [
          "hyprland/workspaces"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "pulseaudio"
          "network"
          "clock"
          "tray"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
        };

        pulseaudio = {
          format = "{volume}% ";
          format-muted = "󰝟";
          scroll-step = 5;
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          tooltip = true;
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "{:%A, %d %B %Y}";
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 12px;
      }

      window#waybar {
        background: rgba(20, 20, 20, 0.9);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 6px;
      }

      #workspaces button.active {
        background: #458588;
      }
    '';
  };
}
