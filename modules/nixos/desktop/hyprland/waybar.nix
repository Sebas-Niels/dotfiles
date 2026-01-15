{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;

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
          on-click = "pavucontrol";
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
    border-bottom: 1px solid rgba(196, 185, 236, 0.92);
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
    background: #458588;
    color: #ffffff;
  }

  #workspaces button:hover {
    background: rgba(69, 133, 136, 0.4);
  }

  #clock,
  #network,
  #pulseaudio,

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
