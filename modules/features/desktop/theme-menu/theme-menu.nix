{ self, ... }:
{
  # palette.nix colours:
  #
  #   bg       window background          text     main text
  #   mantle   bars, darker panels        subtext  dimmed text
  #   surface  raised elements, buttons   accent   focus, selection, active workspace
  #   overlay  borders, selections        accent2  secondary highlight
  #   red / yellow / green               urgent / warning / positive
  flake.nixosModules.themeMenu =
    { pkgs, lib, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system})
        apertureThemes
        apertureTheme
        apertureThemeMenu
        ;
    in
    {
      environment.systemPackages = [
        apertureThemes
        apertureTheme
        apertureThemeMenu
        pkgs.darkly
        pkgs.kdePackages.breeze
        pkgs.kdePackages.breeze.qt5
        pkgs.kdePackages.breeze-gtk
        pkgs.kdePackages.breeze-icons
        pkgs.colloid-icon-theme
      ];

      qt = {
        enable = true;
        platformTheme = "kde";
      };

      programs.dconf.enable = true;
      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Breeze-Dark";
            icon-theme = "Colloid-Dark";
            cursor-theme = "breeze_cursors";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];

      environment.etc =
        lib.genAttrs
          [
            "xdg/gtk-3.0/settings.ini"
            "xdg/gtk-4.0/settings.ini"
          ]
          (_: {
            text = ''
              [Settings]
              gtk-cursor-theme-name=breeze_cursors
              gtk-cursor-theme-size=24
            '';
          });
      environment.pathsToLink = [ "/share/aperture-themes" ];

      environment.sessionVariables.XDG_CONFIG_DIRS = lib.mkBefore [
        "$HOME/.local/state/aperture-theme/current/xdg"
      ];

      system.userActivationScripts.apertureTheme = "${lib.getExe apertureTheme} init";
    };

  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      defaultTheme = "moonlight";

      rgb =
        hex:
        let
          s = lib.removePrefix "#" hex;
          at = i: lib.fromHexString (builtins.substring i 2 s);
        in
        [
          (at 0)
          (at 2)
          (at 4)
        ];
      toHex =
        channels:
        "#"
        + lib.concatMapStrings (v: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString v))) channels;

      helpers = {
        mix =
          a: b: w:
          toHex (lib.zipListsWith (x: y: builtins.floor (x * (1 - w) + y * w + 0.5)) (rgb a) (rgb b));
        bare = lib.removePrefix "#";
        kde = hex: lib.concatMapStringsSep "," toString (rgb hex);
        rgba = hex: alpha: "rgba(${lib.concatMapStringsSep ", " toString (rgb hex)}, ${alpha})";
      };

      gradientWallpaper =
        id: c:
        pkgs.runCommand "${id}-wallpaper.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick -size 960x540 -define gradient:direction=South 'gradient:${c.surface}-${c.mantle}' \
            \( -size 960x540 xc:none -fill '${c.accent}' -draw 'circle 230,120 230,-110' \
               -blur 0x110 -channel A -evaluate multiply 0.45 +channel \) -composite \
            \( -size 960x540 xc:none -fill '${c.accent2}' -draw 'circle 760,470 760,250' \
               -blur 0x130 -channel A -evaluate multiply 0.35 +channel \) -composite \
            -filter Lanczos -resize 3840x2160 -attenuate 0.35 +noise Uniform -quality 92 $out
        '';

      thumbnail =
        id: wallpaper:
        pkgs.runCommand "${id}-thumbnail.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick '${wallpaper}' -resize 'x900>' -quality 88 $out
        '';

      trimTop =
        id: wallpaper: px:
        pkgs.runCommand "${id}-wallpaper.${lib.last (lib.splitString "." (baseNameOf wallpaper))}"
          { nativeBuildInputs = [ pkgs.imagemagick ]; }
          ''
            magick '${wallpaper}' -chop 0x${toString px} -quality 95 $out
          '';

      wallpaperNames = map (ext: "wallpaper.${ext}") [
        "jpg"
        "jpeg"
        "png"
        "webp"
      ];

      themes = lib.mapAttrs (
        id: _:
        let
          dir = ./_themes + "/${id}";
          p = import (dir + "/palette.nix");
          own = lib.findFirst (f: builtins.pathExists (dir + "/${f}")) null wallpaperNames;
          base = if own != null then dir + "/${own}" else gradientWallpaper id p.colors;
          wallpaper = if p ? wallpaperTrimTop then trimTop id base p.wallpaperTrimTop else base;
        in
        helpers
        // {
          inherit id dir wallpaper;
          inherit (p) name variant ansi;
          thumbnail = thumbnail id wallpaper;
          dark = p.variant == "dark";
          icons = if p.variant == "dark" then "Colloid-Dark" else "Colloid-Light";
          c = p.colors;
          term = {
            cursor = p.colors.accent;
            selection = p.colors.overlay;
          }
          // (p.term or { });
        }
      ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_themes));

      orderedThemes = lib.sort (a: b: if a.dark != b.dark then a.dark else a.name < b.name) (
        lib.attrValues themes
      );

      shades =
        t:
        let
          inherit (t) c mix;
        in
        {
          view = if t.dark then c.mantle else mix c.bg "#ffffff" 0.55;
          card = if t.dark then c.surface else mix c.bg "#ffffff" 0.55;
          onAccent = if t.dark then c.bg else mix c.bg "#ffffff" 0.7;
          onYellow = if t.dark then c.bg else c.text;
          ink = color: if t.dark then color else mix color "#000000" 0.15;
          hover = mix c.accent c.bg 0.4;
          raised = mix c.accent c.surface 0.5;
          link = c.accent2;
          visited = mix c.accent2 c.text 0.25;
          unfocusedSelection = mix c.accent c.bg 0.5;
          unfocusedBorders = mix c.overlay c.bg 0.5;
        };

      kdeColors =
        t:
        let
          inherit (t) c kde mix;
          s = shades t;
          group =
            {
              bg,
              alt,
              fg,
              inactive ? c.subtext,
              active ? c.accent,
              link ? s.link,
              visited ? s.visited,
              negative ? c.red,
              neutral ? c.yellow,
              positive ? c.green,
            }:
            ''
              BackgroundNormal=${kde bg}
              BackgroundAlternate=${kde alt}
              ForegroundNormal=${kde fg}
              ForegroundInactive=${kde inactive}
              ForegroundActive=${kde active}
              ForegroundLink=${kde link}
              ForegroundVisited=${kde visited}
              ForegroundNegative=${kde negative}
              ForegroundNeutral=${kde neutral}
              ForegroundPositive=${kde positive}
              DecorationFocus=${kde c.accent}
              DecorationHover=${kde s.hover}
            '';
          onOwn =
            bg: alt: fg:
            let
              over = color: mix color fg 0.75;
            in
            group {
              inherit bg alt fg;
              inactive = mix fg bg 0.2;
              active = over c.accent;
              link = over s.link;
              visited = over s.visited;
              negative = over c.red;
              neutral = over c.yellow;
              positive = over c.green;
            };
        in
        ''
          [General]
          ColorScheme=Aperture${lib.concatStrings (lib.splitString " " t.name)}
          Name=${t.name}
          shadeSortColumn=true

          [KDE]
          contrast=4
          widgetStyle=Darkly

          [Icons]
          Theme=${t.icons}

          [ColorEffects:Disabled]
          Color=${kde c.overlay}
          ColorAmount=0
          ColorEffect=0
          ContrastAmount=0.65
          ContrastEffect=1
          IntensityAmount=0.1
          IntensityEffect=2

          [ColorEffects:Inactive]
          ChangeSelectionColor=true
          Color=${kde c.subtext}
          ColorAmount=0.025
          ColorEffect=2
          ContrastAmount=0.1
          ContrastEffect=2
          Enable=false
          IntensityAmount=0
          IntensityEffect=0

          [Colors:Window]
          ${group {
            bg = c.bg;
            alt = c.mantle;
            fg = c.text;
          }}
          [Colors:View]
          ${group {
            bg = s.view;
            alt = mix s.view c.mantle 0.5;
            fg = c.text;
          }}
          [Colors:Button]
          ${group {
            bg = c.surface;
            alt = s.raised;
            fg = c.text;
          }}
          [Colors:Selection]
          ${onOwn c.accent (s.ink c.accent) s.onAccent}
          [Colors:Tooltip]
          ${if t.dark then onOwn c.surface c.overlay c.text else onOwn c.text (mix c.text c.bg 0.1) c.bg}
          [Colors:Complementary]
          ${group {
            bg = c.mantle;
            alt = c.surface;
            fg = c.text;
          }}
          [Colors:Header]
          ${group {
            bg = c.surface;
            alt = s.raised;
            fg = c.text;
          }}
          [WM]
          activeBackground=${kde c.surface}
          activeForeground=${kde c.text}
          activeBlend=${kde c.accent}
          inactiveBackground=${kde c.bg}
          inactiveForeground=${kde c.subtext}
          inactiveBlend=${kde c.surface}
        '';

      darklyConfig =
        t:
        lib.generators.toINI { } {
          Common = {
            CornerRadius = 8;
            ScrollBarTransient = true;
          };
          Style = {
            DolphinViewOpacity = if t.dark then 55 else 70;
            DolphinSidebarOpacity = if t.dark then 45 else 60;
            MenuOpacity = if t.dark then 85 else 90;
          };
        };

      gtk3Colors =
        t:
        let
          inherit (t) c;
          s = shades t;
        in
        ''
          @define-color theme_bg_color ${c.bg};
          @define-color theme_base_color ${s.view};
          @define-color theme_fg_color ${c.text};
          @define-color theme_text_color ${c.text};
          @define-color theme_selected_bg_color ${c.accent};
          @define-color theme_selected_fg_color ${s.onAccent};
          @define-color insensitive_bg_color ${c.mantle};
          @define-color insensitive_fg_color ${c.subtext};
          @define-color insensitive_base_color ${c.bg};
          @define-color theme_unfocused_bg_color ${c.bg};
          @define-color theme_unfocused_base_color ${s.view};
          @define-color theme_unfocused_fg_color ${c.text};
          @define-color theme_unfocused_text_color ${c.text};
          @define-color theme_unfocused_selected_bg_color ${s.unfocusedSelection};
          @define-color theme_unfocused_selected_fg_color ${c.text};
          @define-color borders ${c.overlay};
          @define-color unfocused_borders ${s.unfocusedBorders};
          @define-color warning_color ${c.yellow};
          @define-color error_color ${c.red};
          @define-color success_color ${c.green};
          @define-color link_color ${s.link};
          @define-color visited_link_color ${s.visited};
        '';

      gtk4Colors =
        t:
        let
          inherit (t) c mix;
          s = shades t;
        in
        ''
          @define-color window_bg_color ${c.bg};
          @define-color window_fg_color ${c.text};
          @define-color view_bg_color ${s.view};
          @define-color view_fg_color ${c.text};
          @define-color headerbar_bg_color ${c.surface};
          @define-color headerbar_fg_color ${c.text};
          @define-color headerbar_border_color ${c.text};
          @define-color headerbar_backdrop_color ${c.mantle};
          @define-color sidebar_bg_color ${c.mantle};
          @define-color sidebar_fg_color ${c.text};
          @define-color sidebar_backdrop_color ${c.bg};
          @define-color secondary_sidebar_bg_color ${mix c.bg c.mantle 0.5};
          @define-color secondary_sidebar_fg_color ${c.text};
          @define-color card_bg_color ${s.card};
          @define-color card_fg_color ${c.text};
          @define-color dialog_bg_color ${c.bg};
          @define-color dialog_fg_color ${c.text};
          @define-color popover_bg_color ${s.card};
          @define-color popover_fg_color ${c.text};
          @define-color accent_bg_color ${c.accent};
          @define-color accent_fg_color ${s.onAccent};
          @define-color accent_color ${s.ink c.accent};
          @define-color destructive_bg_color ${c.red};
          @define-color destructive_fg_color ${s.onAccent};
          @define-color destructive_color ${s.ink c.red};
          @define-color success_bg_color ${c.green};
          @define-color success_fg_color ${s.onAccent};
          @define-color success_color ${s.ink c.green};
          @define-color warning_bg_color ${c.yellow};
          @define-color warning_fg_color ${s.onYellow};
          @define-color warning_color ${s.ink c.yellow};
          @define-color error_bg_color ${c.red};
          @define-color error_fg_color ${s.onAccent};
          @define-color error_color ${s.ink c.red};
        '';

      themeScript = pkgs.writeShellApplication {
        name = "aperture-theme";
        runtimeInputs = with pkgs; [
          coreutils
          procps
          dbus
          dconf
          mako
          awww
        ];
        text = ''
          state="$HOME/.local/state/aperture-theme"
          themes=/run/current-system/sw/share/aperture-themes
          default=${defaultTheme}

          current() {
            local name
            name=$(readlink "$state/current" 2>/dev/null) || true
            name=''${name##*/}
            if [ -n "$name" ] && [ -d "$themes/$name" ]; then
              echo "$name"
            else
              echo "$default"
            fi
          }

          link() {
            mkdir -p "$state"
            ln -sfn "$themes/$1" "$state/.current.$$"
            mv -Tf "$state/.current.$$" "$state/current"

            local v css
            for v in 3.0 4.0; do
              css="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-$v/gtk.css"
              if { [ ! -e "$css" ] && [ ! -L "$css" ]; } || [[ "$(readlink "$css")" == "$state/"* ]]; then
                mkdir -p "''${css%/*}"
                ln -sfn "$state/current/gtk-$v.css" "$css"
              fi
            done
          }

          wallpaper() {
            readlink -f "$state/current/wallpaper"
          }

          reload() {
            if awww query >/dev/null 2>&1; then
              awww img --transition-type grow --transition-pos center --transition-fps 120 \
                --transition-duration 1.2 "$(wallpaper)" || true
            fi

            pkill -USR1 -x '\.?kitty(-wrapped)?' 2>/dev/null || true
            pkill -USR2 -x '\.?ghostty(-wrapped)?' 2>/dev/null || true
            pkill -USR2 -x '\.?waybar(-wrapped)?' 2>/dev/null || true
            makoctl reload >/dev/null 2>&1 || true
            if command -v mmsg >/dev/null; then
              mmsg dispatch load_config_file,/etc/mango/config.conf >/dev/null 2>&1 || true
            fi
            if pgrep -f aperture-coinflip-config >/dev/null; then
              aperture-coinflip reload >/dev/null 2>&1 || true
            fi
            dbus-send --session --type=signal /KGlobalSettings \
              org.kde.KGlobalSettings.notifyChange int32:0 int32:0 || true

            local scheme=prefer-dark gtk=Breeze-Dark icons
            if [ "$(cat "$state/current/variant")" = light ]; then
              scheme=prefer-light gtk=Breeze
            fi
            icons=$(cat "$state/current/icons")
            dconf write /org/gnome/desktop/interface/color-scheme "'$scheme'" || true
            dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk'" || true
            dconf write /org/gnome/desktop/interface/icon-theme "'$icons'" || true
          }

          case "''${1:-}" in
            current) current ;;
            list) ls "$themes" ;;
            init) link "$(current)" ;;
            wallpaper) wallpaper ;;
            reload) reload ;;
            set)
              if [ -z "''${2:-}" ] || [ ! -d "$themes/$2" ]; then
                echo "aperture-theme: unknown theme: ''${2:-}" >&2
                exit 1
              fi
              link "$2"
              reload
              ;;
            *)
              echo "usage: aperture-theme current | list | set <theme> | reload | init | wallpaper" >&2
              exit 1
              ;;
          esac
        '';
      };

      menuThemes = pkgs.writeText "themes.js" ''
        .pragma library

        var list = ${
          builtins.toJSON (
            map (t: {
              inherit (t)
                id
                name
                variant
                ansi
                ;
              colors = t.c;
              wallpaper = "file://${t.wallpaper}";
              thumbnail = "file://${t.thumbnail}";
            }) orderedThemes
          )
        };
      '';

      menuConfig = pkgs.runCommand "aperture-theme-menu-config" { } ''
        mkdir $out
        cp ${pkgs.replaceVars ./shell.qml { themeScript = lib.getExe themeScript; }} $out/shell.qml
        cp ${./ThemeShard.qml} $out/ThemeShard.qml
        cp ${menuThemes} $out/themes.js
      '';
    in
    {
      options.apertureTheme.targets = lib.mkOption {
        type = with lib.types; attrsOf (functionTo str);
        default = { };
        description = ''
          Files rendered for every theme, keyed by their path inside the theme's directory.
          Each value is a function from the theme (palette plus colour helpers) to the contents.
        '';
      };

      config = {
        apertureTheme.targets = {
          "variant" = t: t.variant;
          "icons" = t: t.icons;
          "xdg/kdeglobals" = kdeColors;
          "xdg/darklyrc" = darklyConfig;
          "gtk-3.0.css" = gtk3Colors;
          "gtk-4.0.css" = gtk4Colors;
        };

        packages.apertureThemes = pkgs.linkFarm "aperture-themes" (
          lib.concatLists (
            lib.mapAttrsToList (
              id: t:
              [
                {
                  name = "share/aperture-themes/${id}/wallpaper";
                  path = t.wallpaper;
                }
              ]
              ++ lib.mapAttrsToList (file: render: {
                name = "share/aperture-themes/${id}/${file}";
                path =
                  if builtins.pathExists (t.dir + "/${file}") then
                    t.dir + "/${file}"
                  else
                    pkgs.writeText "${id}-${baseNameOf file}" (render t);
              }) config.apertureTheme.targets
            ) themes
          )
        );

        packages.apertureTheme = themeScript;

        packages.apertureThemeMenu = pkgs.writeShellApplication {
          name = "aperture-theme-menu";
          runtimeInputs = [
            pkgs.quickshell
            pkgs.procps
            pkgs.gnugrep
          ];
          text = ''
            qs() { quickshell -p ${menuConfig} "$@"; }

            pgrep -af 'quickshell.*aperture-theme-menu-config' | grep -vF '${menuConfig}' \
              | while read -r pid _; do kill "$pid" 2>/dev/null || true; done || true

            action="''${1:-toggle}"
            if [ "$action" = daemon ]; then
              exec quickshell -p ${menuConfig} --no-duplicate
            fi

            if ! qs ipc call themes "$action" >/dev/null 2>&1; then
              pkill -f '${menuConfig}' || true
              qs --no-duplicate --daemonize
              for _ in $(seq 30); do
                qs ipc call themes "$action" >/dev/null 2>&1 && exit 0
                sleep 0.1
              done
              exit 1
            fi
          '';
        };
      };
    };
}
