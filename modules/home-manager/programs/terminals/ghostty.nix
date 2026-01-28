{ pkgs, config, username, ... }:

{
    programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrains Nerd Font Mono";
      font-size = 12;
    };
  };
}
