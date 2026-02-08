{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager
  ];

  home.username = "nivis";
  home.homeDirectory = "/home/nivis";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # Common
    discord
    spotify
    tor-browser
    librewolf
    signal-desktop
    obsidian
    fractal # Matrix group messaging app
    yazi-unwrapped # Terminal file explorer
    # vesktop
    brave

    # Util
    wootility
    imhex
    _1password-gui
    kdePackages.kate
    wireshark
    p7zip
    swayimg # Image viewer
    qimgv

    # Games and launchers
    #steam
    prismlauncher-unwrapped # Minecraft
    r2modman

    # Lock screen
    hyprlock
  ];

  # Icons | This might need to just be deleted, think it is for waybar/pavucontrol to have icons
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    colorScheme = "dark";
      theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  # virt-manager: always default to local system connection
  dconf.settings."org/virt-manager/virt-manager/connections" = {
    autoconnect = [ "qemu:///system" ];
    uris = [ "qemu:///system" ];
  };


  # Sets the color themes to darkmode, for Qt + GTK
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "Adwaita-dark";

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  home.file.".config/kdeglobals" = {
    text = ''
      ${builtins.readFile "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors"}
    '';
  };

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;
}
