{ config, pkgs, lib, inputs, ... }:
{
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper;
    settings = {
      preload = [
        "/home/nivis/dotfiles/wallpapers/1361831.jpeg"
      ];
      wallpaper = [
        "DP-1,/home/nivis/dotfiles/wallpapers/1361831.jpeg"
        "DP-2,/home/nivis/dotfiles/wallpapers/1361831.jpeg"
        "DP-3,/home/nivis/dotfiles/wallpapers/1361831.jpeg"
      ];
    };
  };

  systemd.user.services.hyprpaper = {
    Unit.After = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
    Service.ExecStart = lib.mkForce [
      ""
      "${inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper}/bin/hyprpaper --config ${config.xdg.configHome}/hypr/hyprpaper.conf"
    ];
  };
}