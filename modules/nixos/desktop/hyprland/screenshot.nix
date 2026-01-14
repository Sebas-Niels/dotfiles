{ }{ config, pkgs, lib, ... }:

let
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
in
{
  # Ensure directory exists
  home.activation.createScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${screenshotDir}
  '';

  # Required packages
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    libnotify
  ];

  # Hyprland keybindings
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Area → file
      "SUPER, S, exec, grim -g \"$(slurp)\" ${screenshotDir}/shot-$(date +%F-%T).png"

      # Area → clipboard
      "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

      # Fullscreen → clipboard
      "SUPER, Print, exec, grim - | wl-copy"

      # Fullscreen → file
      "SUPER SHIFT, Print, exec, grim ${screenshotDir}/shot-$(date +%F-%T).png"
    ];
  };
}
