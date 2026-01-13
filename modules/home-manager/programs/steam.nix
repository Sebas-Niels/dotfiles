{ pkgs, ... }:

{

    programs.steam.enable = {
      enable = true;
      gamescopeSession.enable = true;
    };

    programs.gamemode.enable = true;

}
