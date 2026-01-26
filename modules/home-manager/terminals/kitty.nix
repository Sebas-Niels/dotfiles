{ pkgs, config, username, ... }:

{
    programs.kitty = {
        enable = true;
        font = {
            name = "JetBrainsMono Nerd Font Mono";
            size = 12.0;
        };
        settings = {
            adjust_line_height = "110%";
        };
    };
}
