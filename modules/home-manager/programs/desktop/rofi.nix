{ pkgs, ... }:
let
  rofiThemesCollection = pkgs.fetchFromGitHub {
    owner = "newmanls";
    repo = "rofi-themes-collection";
    rev = "master";
    hash = "sha256-YdsuzmpU/fokvF1/vKuiK/eOLFGfhJcFu8HvUIqx9Ao=";
  };
in
{
  # Makes themes browsable in ~/.config (e.g. for rofi-theme-selector)
  home.file.".config/rofi/themes".source = "${rofiThemesCollection}/themes";

  programs.rofi = {
    enable = true;
    extraConfig = {
      show-icons = true;
    };
    theme = "${rofiThemesCollection}/themes/rounded-pink-dark.rasi";
  };
}
