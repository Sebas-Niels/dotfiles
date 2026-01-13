{ config, pkgs, inputs, ... }:

{

  imports = [
    ../../modules/home-manager/scripts/silent-sound.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nixtest";
  home.homeDirectory = "/home/nixtest";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    discord
    steam
    imhex
    spotify
    tor-browser
    librewolf

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
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
      kb_layout = "us";
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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nixos/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
