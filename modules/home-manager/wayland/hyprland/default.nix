{ config, pkgs, inputs, ... }:

{

  imports = [
    ./keybinds.nix
    ./workspaces.nix
    ./hyprpaper.nix
    ./clipboard.nix
    ./screenshot.nix
    ./defapps.nix
  ];


  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.system}.borders-plus-plus
    ];

    settings = {

      #############################
      # MONITOR
      #############################

      monitor = [
        "DP-1,1920x1200@59.95,2560x120,1"
        "DP-2,2560x1440@164.96,0x0,1"
        "DP-3,1920x1200@59.95,-1920x120,1"
      ];

      #############################
      # AUTOSTART
      #############################

      exec-once = [
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP"
        "systemctl --user stop hyprland-session.target"
        "systemctl --user start hyprland-session.target"
        "swww init"
        "waybar"
        "dunst"
      ];

      #############################
      # INPUT / GENERAL / DECORATION
      #############################

      input = {
        kb_layout = "dk";
        follow_mouse = 1;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
      };

      #############################
      # PLUGIN CONFIG
      #############################

      "plugin:borders-plus-plus" = {
        add_borders = 1;
        border_size_1 = 10;
        border_size_2 = -1;
        "col.border_1" = "rgb(ffffff)";
        "col.border_2" = "rgb(2222ff)";
        natural_rounding = "yes";
      };
    };
  };
}
