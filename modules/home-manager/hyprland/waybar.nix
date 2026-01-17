{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;

        margin-top = 10;
        margin-right = 10;
        margin-left = 10;



        modules-left = [
          "hyprland/window"
        ];

        modules-center = [
          "hyprland/workspaces"

        ];

        modules-right = [
          "wireplumber"
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

        wireplumber = {
          format = "{volume}% ";
          format-muted = "󰝟";
          scroll-step = 5;
          on-click = "hyprpwcenter";
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
    font-size: 16px;
    border: none;
    border-radius: 0;
    min-height: 0;
  }

  window#waybar {
    background: rgba(29, 28, 44, 0.92);
    color: #ebdbb2;
    border-radius: 8px;
  }

  #workspaces {
    margin-left: 6px;
  }

  #workspaces button {
    padding: 0 8px;
    margin: 4px 2px;
    border-radius: 6px;
    background: transparent;
    color: #bdae93;
  }

  #workspaces button.active {
    background: #feb3ff;
    color: #000000;
  }

  #workspaces button:hover {
    background: rgba(255, 255, 255, 1);
    color: #000000;
  }

  #clock,
  #network,
  #wireplumber,

  #tray {
    padding: 0 10px;
    margin: 4px 2px;
    border-radius: 6px;
    background: rgba(40, 40, 40, 0.8);
  }

  #tray {
    padding-right: 6px;
  }

  tooltip {
    background: #282828;
    color: #ebdbb2;
    border-radius: 6px;
    padding: 6px 8px;
  }
'';

  };
}
