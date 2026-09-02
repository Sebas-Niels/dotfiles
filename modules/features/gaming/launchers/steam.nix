{ self, inputs, ... }:
{
  flake.nixosModules.steam = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;

      package = pkgs.steam.override {
        extraProfile = ''
          export PULSE_SERVER=none
        '';
      };
    };

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

environment.systemPackages = with pkgs; [
  labwc
  (writeShellScriptBin "steam-labwc" ''
    exec ${labwc}/bin/labwc -s steam
  '')
  (makeDesktopItem {
  name = "steam-labwc";
  desktopName = "Steam (labwc)";
  exec = "steam-labwc";
  icon = "steam";
  categories = [ "Game" ];
})
  protontricks
  protonup-ng
  scanmem
];



    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/user/.steam/root/compatibilitytools.d";
    };

  };
}
