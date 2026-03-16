{ pkgs, config, username, ... }:

{
    programs.kitty = {
        enable = true;
        font = {
            name = "JetBrainsMono Nerd Font";
            size = 14.0;
        };
        settings = {
            adjust_line_height = "120%";
            background_opacity = "1";

        };
        themeFile = "gruvbox-dark";
    };
}
