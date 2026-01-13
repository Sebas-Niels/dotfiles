{ config, pkgs, inputs, ... }:

{

  imports = [
    ../../modules/home-manager/scripts/silent-sound.nix
    ../../modules/nixos/desktop/hyprland/waybar.nix

  ];

  home.username = "nixtest";
  home.homeDirectory = "/home/nixtest";

  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = with pkgs; [

    # Common
    discord
    spotify
    tor-browser
    librewolf # Need to make this into seperate package for customization
    signal-desktop

    # Util
    wootility
    imhex
    _1password-gui
    kdePackages.kate

    # Games and launchers
    steam
    prismlauncher-unwrapped # Java and drivers need to be managed
    r2modman
  ];

  wayland.windowManager.hyprland = {
  enable = true;

  plugins = [
    inputs.hyprland-plugins.packages.${pkgs.system}.borders-plus-plus
  ];

  settings = {
    #############################
    # AUTOSTART
    #############################

    monitor = [
      # Right monitor
      "DP-1,1920x1200@59.95,2560x120,1"
æk      # Middle monitor
      "DP-2,2560x1440@164.96,0x0,1"
      # Left monitor
      "DP-3,1920x1200@59.95,-1920x120,1"
    ];


    exec-once = [
      "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP"
      "systemctl --user stop hyprland-session.target"
      "systemctl --user start hyprland-session.target"
      "swww init"
      "waybar"
      "dunst"
    ];

    #############################
    # MOD KEY
    #############################

    "$mod" = "SUPER";

    #############################
    # KEYBINDS
    #############################

    bind = [
      "$mod, Return, exec, kitty"
      "$mod SHIFT, Return, exec, foot"
      "$mod, D, exec, rofi -show drun"

      "$mod, Q, killactive"
      "$mod, F, fullscreen"
      "$mod, M, exit"

      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      "$mod SHIFT, H, movewindow, l"
      "$mod SHIFT, L, movewindow, r"
      "$mod SHIFT, K, movewindow, u"
      "$mod SHIFT, J, movewindow, d"
    ];

    #############################
    # INPUT / GENERAL
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



  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
