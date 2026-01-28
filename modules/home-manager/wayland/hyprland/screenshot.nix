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

    # Area → clipboard
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

    # Fullscreen → clipboard
    bind = SUPER, Print, exec, grim - | wl-copy
 '';
}



# THIS NEEDS TO BE MOVED TO A SCREENSHOT MODULE, AND THE KEYBIND NEEDS TO BE MOVED TO KEYBINDINGS MODULE
