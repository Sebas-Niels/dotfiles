{ self, inputs, ... }: {
    flake.nixosModules.niri = { pkgs, lib, ... }: {
        programs.niri = {
            enable = true;
            package = self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaNiri;
        };
    };
    perSystem = { pkgs, lib, self', ... }: {
        packages.lambdaNiri = inputs.wrapper-modules.wrappers.niri.wrap {
            inherit pkgs;
            settings = {

                screenshot-path = null;
                
                environment = {
                    QS_ICON_THEME = "Papirus-Dark";
                    XCURSOR_THEME = "breeze_cursors";
                    XCURSOR_SIZE = "24";
                };

                cursor = {
                    xcursor-theme = "breeze_cursors";
                    xcursor-size = 24;
                    hide-when-typing = false;
                };

                spawn-at-startup = [
                    (lib.getExe self'.packages.lambdaNoctalia)
                ];

                outputs = {
                    # centre — 2560x1440, pinned to its high refresh mode
                    "Dell Inc. AW2724DM GFGYHV3" = {
                        mode = "2560x1440@143.973";
                        position = _: { props = { x = 1920; y = 0; }; };
                        focus-at-startup = _: { };
                    };
                    # left
                    "Samsung Electric Company SyncMaster H9XB408702" = {
                        mode = "1920x1200@59.950";
                        position = _: { props = { x = 0; y = 120; }; };
                    };
                    # right
                    "Samsung Electric Company SyncMaster H9XZ111348" = {
                        mode = "1920x1200@59.950";
                        position = _: { props = { x = 4480; y = 120; }; };
                    };
                };

                xwayland-satellite.path =
                    lib.getExe pkgs.xwayland-satellite;

                input.keyboard = {
                    xkb.layout = "dk";
                };
                layout.gaps = 5;
                binds = {
                    "Mod+D".spawn-sh =
                        "${lib.getExe self'.packages.lambdaNoctalia} ipc call launcher toggle";
                    "Mod+Return".spawn-sh = lib.getExe self'.packages.lambdaKitty;
                    "Mod+Q".close-window = _: { };

                    "Print".screenshot = _: { };
                };
            };
        };
    };
}
