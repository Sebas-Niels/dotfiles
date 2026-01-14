{ config, pkgs, lib, ... }:

let
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
in
{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    libnotify
  ];

  home.activation.createScreenshotDir =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${screenshotDir}
    '';

  wayland.windowManager.hyprland.extraConfig = ''
    # Screenshot bindings

    # Area → file
    bind = SUPER, S, exec, grim -g "$(slurp)" ${screenshotDir}/shot-$(date +%F-%T).png

    # Area → clipboard
    bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy

    # Fullscreen → clipboard
    bind = SUPER, Print, exec, grim - | wl-copy

    # Fullscreen → file
    bind = SUPER SHIFT, Print, exec, grim ${screenshotDir}/shot-$(date +%F-%T).png
  '';
}
