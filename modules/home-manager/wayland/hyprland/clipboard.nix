{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    cliphist
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    # Clipboard persistence (Wayland)
    exec-once = wl-paste --type text --watch cliphist store
    exec-once = wl-paste --type image --watch cliphist store

    # Clipboard history picker (Super + V)
    bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
  '';
}
