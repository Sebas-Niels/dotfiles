{ config, pkgs, inputs, ... }:

{
  imports = [
    #../../modules/home-manager/scripts/silent-sound.nix
    ../../modules/home-manager/hyprland/waybar.nix
    ../../modules/home-manager/programs/git.nix
    ../../modules/home-manager/hyprland/screenshot.nix
    ../../modules/home-manager/hyprland/clipboard.nix
    ../../modules/home-manager/hyprland/workspaces.nix
    ../../modules/home-manager/hyprland/wireplumber.nix
    ../../modules/home-manager/hyprland/dunst.nix
    ../../modules/home-manager/terminals/kitty.nix
    #../../modules/home-manager/noctalia/noctalia.nix
    ../../modules/home-manager/hyprland/hyprland.nix

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

    # Util
    wootility
    imhex
    _1password-gui
    kdePackages.kate
    wireshark
    p7zip
    swayimg # Image viewer

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

  # Wallpaper
  services.hyprpaper = {
    enable = true;

    settings = {
      preload = [
        "/home/nivis/dotfiles/wallpapers/116123703_p0.jpg"
      ];

      wallpaper = [
        "DP-1,/home/nivis/dotfiles/wallpapers/116123703_p0.jpg"
        "DP-2,/home/nivis/dotfiles/wallpapers/116123703_p0.jpg"
        "DP-3,/home/nivis/dotfiles/wallpapers/116123703_p0.jpg"
      ];
    };
  };



  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;
}
