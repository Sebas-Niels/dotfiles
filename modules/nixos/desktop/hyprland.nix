{ config, pkgs, lib, ... }:

{
  services.getty.autologinUser = "nixtest";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;

  };

  environment.systemPackages = with pkgs; [
    kitty
    waybar
    hyprpaper
    foot
  ];
}
