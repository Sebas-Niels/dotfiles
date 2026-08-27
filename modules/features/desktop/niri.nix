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

                prefer-no-csd = _: { };
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

                input = {
                    focus-follows-mouse = _: { props.max-scroll-amount = "0%"; };
                    keyboard = {
                        xkb.layout = "dk";
                        numlock = _: { };
                    };
                };

                gestures.hot-corners.off = _: { };

                layout.gaps = 5;
                binds = {
                    "Mod+D".spawn-sh =
                        "${lib.getExe self'.packages.lambdaNoctalia} ipc call launcher toggle";
                    "Mod+Return".spawn-sh = lib.getExe self'.packages.lambdaKitty;
                    "Mod+Q".close-window = _: { };
                    "Mod+O".toggle-overview = _: { };
                    "Print".screenshot = _: { };

                    "Mod+F".maximize-column = _: { };
                    "Mod+Ctrl+F".fullscreen-window = _: { };
                    "Mod+Shift+F".expand-column-to-available-width = _: { };

                    "Mod+Comma".consume-window-into-column = _: { };
                    "Mod+Period".expel-window-from-column = _: { };


                      # scroll focus left/right through columns
                    "Mod+H".focus-column-left = _: { };
                    "Mod+L".focus-column-right = _: { };
                    "Mod+Left".focus-column-left = _: { };
                    "Mod+Right".focus-column-right = _: { };

                    # drag the focused column along with you
                    "Mod+Ctrl+H".move-column-left = _: { };
                    "Mod+Ctrl+L".move-column-right = _: { };
                    "Mod+Ctrl+Left".move-column-left = _: { };
                    "Mod+Ctrl+Right".move-column-right = _: { };

                    # jump to the ends of the scrollable row
                    "Mod+Home".focus-column-first = _: { };
                    "Mod+End".focus-column-last = _: { };
                    "Mod+Ctrl+Home".move-column-to-first = _: { };
                    "Mod+Ctrl+End".move-column-to-last = _: { };

                    # mouse wheel scrolling
                    "Mod+WheelScrollRight".focus-column-right = _: { };
                    "Mod+WheelScrollLeft".focus-column-left = _: { };
                    "Mod+WheelScrollDown".focus-column-right = _: { };
                    "Mod+WheelScrollUp".focus-column-left = _: { };
                };
            };
        };
    };
}
