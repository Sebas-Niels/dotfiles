{ ... }: {
  flake.nixosModules.sddm =
    { pkgs, ... }:
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

            // Blank the pointer on every screen, not just the primary one.
            // enabled: false so it never swallows events meant for the form.
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
    in
    {
      services.xserver.enable = true;

      services.xserver.displayManager.setupCommands = ''
        ${pkgs.xrandr}/bin/xrandr --output DP-2 --primary
        ${pkgs.xdotool}/bin/xdotool mousemove 1280 720

        (
          for i in $(${pkgs.coreutils}/bin/seq 1 20); do
            ${pkgs.coreutils}/bin/sleep 1
            eval "$(${pkgs.xdotool}/bin/xdotool getmouselocation --shell 2>/dev/null)"
            [ -n "$WINDOW" ] && [ "$WINDOW" != 0 ] || continue
            ${pkgs.xprop}/bin/xprop -id "$WINDOW" WM_CLASS 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -qi sddm || continue
            ${pkgs.xdotool}/bin/xdotool windowfocus "$WINDOW" && break
          done
        ) > /tmp/greeter-focus.txt 2>&1 &
      '';

      services.displayManager.sddm = {
        enable = true;
        theme = "${theme}/share/sddm/themes/where_is_my_sddm_theme";
        extraPackages = [ theme ];
      };
    };
}
