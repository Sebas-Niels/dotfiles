{ config, pkgs, input, ... }:

{
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
}
