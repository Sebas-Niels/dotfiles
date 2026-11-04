{ ... }: {
  flake.nixosModules.sddm =
    { config, pkgs, ... }:
    let
      mainQml = pkgs.writeText "Main.qml" ''
        import QtQuick 2.15

        Rectangle {
            width: 640
            height: 480
            color: config.stringValue("backgroundFill") || "#000000"

            Loader {
                anchors.fill: parent
                focus: true
                active: primaryScreen
                source: "MainContent.qml"
            }

            MouseArea {
                anchors.fill: parent
                enabled: false
                cursorShape: Qt.BlankCursor
            }
        }
      '';

      theme =
        (pkgs.where-is-my-sddm-theme.override {
          themeConfig.General = {
            passwordCharacter = "*";
            passwordFontSize = 96;
            backgroundFill = "#000000";
            basicTextColor = "#ffffff";
          };
        }).overrideAttrs
          (old: {
            postFixup = (old.postFixup or "") + ''
              d=$out/share/sddm/themes/where_is_my_sddm_theme
              mv "$d/Main.qml" "$d/MainContent.qml"
              cp ${mainQml} "$d/Main.qml"
            '';
          });

      # Only DP-1 is lit, so the greeter's one window always has keyboard focus.
      westonIni = pkgs.writeText "weston.ini" ''
        [core]
        idle-time=600

        [keyboard]
        keymap_layout=${config.services.xserver.xkb.layout}
        keymap_variant=${config.services.xserver.xkb.variant}

        [output]
        name=DP-1
        mode=preferred

        [output]
        name=DP-2
        mode=off

        [output]
        name=DP-3
        mode=off
      '';
    in
    {
      services.displayManager.sddm = {
        enable = true;
        theme = "${theme}/share/sddm/themes/where_is_my_sddm_theme";
        extraPackages = [ theme ];
        wayland = {
          enable = true;
          compositorCommand = "${pkgs.lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
        };
      };
    };
}
