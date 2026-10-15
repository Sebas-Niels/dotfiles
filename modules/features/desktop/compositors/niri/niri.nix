{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.apertureNiri;
    };
  };
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.apertureNiri = inputs.wrapper-modules.wrappers.niri.wrap {
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
            (lib.getExe self'.packages.apertureNoctalia)
          ];

          window-rules = [
            {
              match = _: { props.app-id = "^kitty-float$"; };
              open-floating = true;
              default-column-width.fixed = 1620;
              default-window-height.fixed = 910;
            }
          ];

          outputs = {
            # centre — 3440x1440 ultrawide, pinned to its high refresh mode
            "Dell Inc. AW3425DWM BH96444" = {
              mode = "3440x1440@179.989";
              position = _: {
                props = {
                  x = 0;
                  y = 0;
                };
              };
              focus-at-startup = _: { };
            };
            # right — 2560x1440, pinned to its high refresh mode
            "Dell Inc. AW2724DM GFGYHV3" = {
              mode = "2560x1440@143.973";
              position = _: {
                props = {
                  x = 3440;
                  y = 0;
                };
              };
            };
            # bottom — Corsair Xeneon Edge, centred under the ultrawide
            "Cyrix Corporation XENEON EDGE 578526065656" = {
              mode = "2560x720@60.266";
              scale = 1.0;
              position = _: {
                props = {
                  x = 440;
                  y = 1440;
                };
              };
            };
          };


          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input = {
            focus-follows-mouse = _: { props.max-scroll-amount = "0%"; };
            keyboard = {
              xkb.layout = "us";
              numlock = _: { };
            };
            touch = {
              map-to-output = "Cyrix Corporation XENEON EDGE 578526065656";
            };
          };

          gestures.hot-corners.off = _: { };

          layout.gaps = 5;
          binds = {
            "Mod+D".spawn-sh = "${lib.getExe self'.packages.apertureNoctalia} ipc call launcher toggle";
            "Mod+Shift+Return".spawn-sh = lib.getExe self'.packages.apertureKitty;
            "Mod+Return".spawn-sh =
              "${lib.getExe self'.packages.apertureKitty} --class=kitty-float ${lib.getExe self'.packages.apertureZsh} -c '${lib.getExe self'.packages.apertureFastfetch}; exec ${lib.getExe self'.packages.apertureZsh}' & sleep 0.3 && niri msg action center-window";
            "Mod+Q".close-window = _: { };
            "Mod+O".toggle-overview = _: { };
            "Print".screenshot = _: { };

            "Mod+F".maximize-column = _: { };
            "Mod+Ctrl+F".fullscreen-window = _: { };
            "Mod+Shift+F".expand-column-to-available-width = _: { };

            "Mod+Comma".consume-window-into-column = _: { };
            "Mod+Period".expel-window-from-column = _: { };

            # WHAT IS THE KEYBIND FOR LOCKING NIRI?!?!??!?!?!
            "Ctrl+Alt+L".spawn-sh = "${lib.getExe self'.packages.apertureNoctalia} ipc call lockScreen lock";

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
