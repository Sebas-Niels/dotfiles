{ config, pkgs, lib, inputs, ... }:

{
  #services.getty.autologinUser = "nixtest";

  imports = [
  ];


  programs.hyprland = {
    enable = true;
    xwayland = {
        enable = true;
      };


    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };

  services.displayManager.sessionPackages = [
  pkgs.hyprland
];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = true;
  hardware.nvidia.open = false;

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    #waybar
    #hyprpaper
    foot
    dunst
    libnotify
    swww
    rofi
    wireplumber
    pavucontrol
    hyprpwcenter
  ];

services.pipewire = {
  enable = true;

  pulse.enable = true;        # REQUIRED for pavucontrol
  wireplumber.enable = true;  # REQUIRED
};



  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
