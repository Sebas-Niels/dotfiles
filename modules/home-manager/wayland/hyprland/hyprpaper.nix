{ config, pkgs, lib, inputs, ... }:
{
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper;
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

  systemd.user.services.hyprpaper = {
    Unit.After = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
    Service.ExecStart = lib.mkForce [
      ""
      "${inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper}/bin/hyprpaper --config ${config.xdg.configHome}/hypr/hyprpaper.conf"
    ];
  };
}