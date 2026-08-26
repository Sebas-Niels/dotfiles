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
            protontricks
            protonup-ng 
            scanmem

        ];

        environment.sessionVariables = {
            STEAM_EXTRA_COMPAT_TOOLS_PATHS =
                "/home/user/.steam/root/compatibilitytools.d";
        };

    };
}