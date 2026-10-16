{ self, ... }:
{
  # Runtime theme switching. Every theme folder in _themes/ is rendered at build time into
  # /run/current-system/sw/share/aperture-themes/<theme>/: its wallpaper, plus one file per app
  # (each app module adds its file through apertureTheme.targets). The apps read their colours
  # through the symlink ~/.local/state/aperture-theme/current, which the quickshell menu (SUPER+T)
  # re-points before telling every running app to reload.
  #
  # A theme folder holds (import-tree skips _themes/, so none of it is a flake module):
  #
  #   palette.nix      name, variant, colours and terminal palette, see below
  #   wallpaper.*      jpg, jpeg, png or webp; without one, a gradient is drawn from the palette
  #   <target file>    optional; used as-is instead of that app's generated file, named as in
  #                    apertureTheme.targets (kitty.conf, waybar.css, xdg/kdeglobals, ...)
  #
  # palette.nix colours:
  #
  #   bg       window background          text     main text
  #   mantle   bars, darker panels        subtext  dimmed text
  #   surface  raised elements, buttons   accent   focus, selection, active workspace
  #   overlay  borders, selections        accent2  secondary highlight
  #   red / yellow / green               urgent / warning / positive
  #
  # ansi is the 16-colour terminal palette (color0 .. color15); term overrides the terminal-only
  # colours (cursor, selection) where a theme's own port differs from the derived defaults.
  # wallpaperTrimTop optionally cuts that many pixels off the top of the wallpaper, which moves
  # it up on screen to show more of its bottom.
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
        # What the themes are drawn on: Breeze widgets for Qt and GTK, recoloured per theme,
        # and the icon themes they switch between
        pkgs.kdePackages.breeze
        pkgs.kdePackages.breeze-gtk
        pkgs.kdePackages.breeze-icons
        pkgs.papirus-icon-theme
      ];

      # Qt apps read their colours from kdeglobals only on the KDE platform theme
      qt = {
        enable = true;
        platformTheme = "kde";
        style = "breeze";
      };

      # Light/dark preference, GTK theme and icons are set here on every switch; these defaults
      # match the default theme (Moonlight) until one is picked
      programs.dconf.enable = true;
      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Breeze-Dark";
            icon-theme = "Papirus-Dark";
            cursor-theme = "breeze_cursors";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];

      # Only the cursor: a theme or dark preference here would pin GTK apps over the switches
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

      # KDE/Qt apps (Dolphin) cascade kdeglobals over XDG_CONFIG_DIRS, so putting the current
      # theme first recolours them without touching ~/.config/kdeglobals
      environment.sessionVariables.XDG_CONFIG_DIRS = lib.mkBefore [
        "$HOME/.local/state/aperture-theme/current/xdg"
      ];

      # Make sure the current-theme link exists before anything reads through it
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

      # Colour helpers handed to every renderer next to the palette
      helpers = {
        # Blend a towards b by w (0..1)
        mix =
          a: b: w:
          toHex (lib.zipListsWith (x: y: builtins.floor (x * (1 - w) + y * w + 0.5)) (rgb a) (rgb b));
        # "#89b4fa" -> "89b4fa"
        bare = lib.removePrefix "#";
        # "#89b4fa" -> "137,180,250"
        kde = hex: lib.concatMapStringsSep "," toString (rgb hex);
        # "#89b4fa" "0.9" -> "rgba(137, 180, 250, 0.9)"
        rgba = hex: alpha: "rgba(${lib.concatMapStringsSep ", " toString (rgb hex)}, ${alpha})";
      };

      # Soft glows of the two accents over the palette's background, for themes without a
      # wallpaper of their own. Drawn small and scaled up, since the blur is the slow part.
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

      # Small copy for the menu's strip, so it never has to decode a dozen full-size wallpapers
      thumbnail =
        id: wallpaper:
        pkgs.runCommand "${id}-thumbnail.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick '${wallpaper}' -resize 'x900>' -quality 88 $out
        '';

      # Keeps the extension, which awww goes by
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
          c = p.colors;
          term = {
            cursor = p.colors.accent;
            selection = p.colors.overlay;
          }
          // (p.term or { });
        }
      ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_themes));

      # Dark themes first, then alphabetical
      orderedThemes = lib.sort (a: b: if a.dark != b.dark then a.dark else a.name < b.name) (
        lib.attrValues themes
      );

      # Colours the app renderers share, worked out from the palette the way Windmill Light was
      # first tuned by hand: views and cards a step lighter than the window on light themes,
      # light text on the accent there, and darkened accents wherever they are drawn as text
      shades =
        t:
        let
          inherit (t) c mix;
        in
        {
          view = if t.dark then c.mantle else mix c.bg "#ffffff" 0.55;
          # Cards and popovers sit above the window: the lighter view on light themes, surface on dark
          card = if t.dark then c.surface else mix c.bg "#ffffff" 0.55;
          onAccent = if t.dark then c.bg else mix c.bg "#ffffff" 0.7;
          # The yellow is light on dark themes and dark on light ones
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
          # For groups with a background of their own (selection, tooltips): every foreground is
          # pulled towards the group's text so it stays legible on that background
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
          widgetStyle=Breeze

          [Icons]
          Theme=${if t.dark then "Papirus-Dark" else "Papirus-Light"}

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
          ${
            # A dark tooltip on light themes, a raised one on dark themes
            if t.dark then onOwn c.surface c.overlay c.text else onOwn c.text (mix c.text c.bg 0.1) c.bg
          }
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

      # Breeze-GTK has its colours baked in, so this mostly reaches libadwaita (GTK4) apps and
      # GTK3 themes that use the named colours
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
            # Swap the link atomically so nothing ever reads through a missing one
            ln -sfn "$themes/$1" "$state/.current.tmp"
            mv -Tf "$state/.current.tmp" "$state/current"

            # GTK only reads gtk.css from the user's own config dir; never replace one the user wrote
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
            # Only once aperture-swww has the daemon up; it sets the wallpaper itself at login
            if awww query >/dev/null 2>&1; then
              awww img --transition-type grow --transition-pos center --transition-fps 120 \
                --transition-duration 1.2 "$(wallpaper)" || true
            fi

            # Wrapped binaries show up as .<name>-wrapped (cut to 15 characters)
            pkill -USR1 -x '\.?kitty(-wrapped)?' || true
            pkill -USR2 -x '\.?ghostty(-wrapped?)?' || true
            pkill -USR2 -x '\.?waybar(-wrapped)?' || true
            makoctl reload >/dev/null 2>&1 || true
            if command -v mmsg >/dev/null; then
              mmsg dispatch load_config_file,/etc/mango/config.conf >/dev/null 2>&1 || true
            fi
            # Qt apps on the KDE platform theme (Dolphin) re-read kdeglobals on this signal
            dbus-send --session --type=signal /KGlobalSettings \
              org.kde.KGlobalSettings.notifyChange int32:0 int32:0 || true

            local scheme=prefer-dark gtk=Breeze-Dark icons=Papirus-Dark
            if [ "$(cat "$state/current/variant")" = light ]; then
              scheme=prefer-light gtk=Breeze icons=Papirus-Light
            fi
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
          "xdg/kdeglobals" = kdeColors;
          "gtk-3.0.css" = gtk3Colors;
          "gtk-4.0.css" = gtk4Colors;
        };

        packages.apertureThemes = pkgs.linkFarm "aperture-themes" (
          lib.concatLists (
            lib.mapAttrsToList (
              id: t:
              [
                {
                  # Resolves to a file that keeps its extension, which awww goes by
                  name = "share/aperture-themes/${id}/wallpaper";
                  path = t.wallpaper;
                }
              ]
              ++ lib.mapAttrsToList (file: render: {
                name = "share/aperture-themes/${id}/${file}";
                # A file of the same name in the theme's folder wins over the generated one
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

        # aperture-theme-menu [toggle|open|close] drives the running menu; `daemon` starts it
        packages.apertureThemeMenu = pkgs.writeShellApplication {
          name = "aperture-theme-menu";
          runtimeInputs = [
            pkgs.quickshell
            pkgs.procps
            pkgs.gnugrep
          ];
          text = ''
            qs() { quickshell -p ${menuConfig} "$@"; }

            # Menus started from an earlier build keep running their old config; stop them so
            # only this build's menu is ever around
            pgrep -af 'quickshell.*aperture-theme-menu-config' | grep -vF '${menuConfig}' \
              | while read -r pid _; do kill "$pid" 2>/dev/null || true; done || true

            action="''${1:-toggle}"
            if [ "$action" = daemon ]; then
              exec quickshell -p ${menuConfig} --no-duplicate
            fi

            if ! qs ipc call themes "$action" >/dev/null 2>&1; then
              # Not running, or wedged: start it over
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
