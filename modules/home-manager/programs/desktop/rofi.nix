{ pkgs, ... }:

let
  rofiThemesCollection = pkgs.fetchFromGitHub {
    owner = "newmanls";
    repo = "rofi-themes-collection";
    rev = "master";
    sha256 = "sha256-96wSyOp++1nXomnl8rbX5vMzaqRhTi/N7FUq6y0ukS8=";
  };
in
{
  # Optional but recommended: makes themes show up like normal in ~/.config
  home.file.".config/rofi/themes".source =
    "${rofiThemesCollection}/themes";

  programs.rofi = {
    enable = true;

    extraConfig = {
        show-icons = true;
    };

    # Use a real path (this is the important part)
    theme = "~/.config/rofi/themes/rounded-pink-dark.rasi";
  };
}
