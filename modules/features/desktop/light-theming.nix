{ ... }:
{
  flake.nixosModules.lightTheming =
    { pkgs, lib, ... }:
    let
      # ---------------------------------------------------------------------
      # Palette
      # ---------------------------------------------------------------------
      # cream      #F7E9D6   247,233,214   window background
      # paper      #FCF5EA   252,245,234   view / entry background
      # beige      #EDD1AE   237,209,174   buttons, titlebars
      # apricot    #E3A876   227,168,118   hover
      # orange     #C9723F   201,114,63    selection / focus (use sparingly)
      # rose       #D4899A   212,137,154   secondary highlight
      # mauve      #8C5A6B   140,90,107    links
      # sage       #96A57B   150,165,123   positive
      # ink        #4A3B42    74,59,66     text
      # ---------------------------------------------------------------------

      colorScheme = pkgs.writeText "WindmillLight.colors" ''
        [General]
        ColorScheme=WindmillLight
        Name=Windmill Light
        shadeSortColumn=true

        [KDE]
        contrast=4
        widgetStyle=Breeze

        [Icons]
        Theme=Papirus-Light

        [ColorEffects:Disabled]
        Color=200,186,168
        ColorAmount=0
        ColorEffect=0
        ContrastAmount=0.65
        ContrastEffect=1
        IntensityAmount=0.1
        IntensityEffect=2

        [ColorEffects:Inactive]
        ChangeSelectionColor=true
        Color=140,120,110
        ColorAmount=0.025
        ColorEffect=2
        ContrastAmount=0.1
        ContrastEffect=2
        Enable=false
        IntensityAmount=0
        IntensityEffect=0

        [Colors:Window]
        BackgroundNormal=247,233,214
        BackgroundAlternate=241,224,201
        ForegroundNormal=74,59,66
        ForegroundInactive=122,107,112
        ForegroundActive=201,114,63
        ForegroundLink=140,90,107
        ForegroundVisited=122,74,92
        ForegroundNegative=176,75,63
        ForegroundNeutral=201,132,63
        ForegroundPositive=95,122,69
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [Colors:View]
        BackgroundNormal=252,245,234
        BackgroundAlternate=245,235,220
        ForegroundNormal=74,59,66
        ForegroundInactive=122,107,112
        ForegroundActive=201,114,63
        ForegroundLink=140,90,107
        ForegroundVisited=122,74,92
        ForegroundNegative=176,75,63
        ForegroundNeutral=201,132,63
        ForegroundPositive=95,122,69
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [Colors:Button]
        BackgroundNormal=237,209,174
        BackgroundAlternate=227,168,118
        ForegroundNormal=74,59,66
        ForegroundInactive=122,107,112
        ForegroundActive=201,114,63
        ForegroundLink=140,90,107
        ForegroundVisited=122,74,92
        ForegroundNegative=176,75,63
        ForegroundNeutral=201,132,63
        ForegroundPositive=95,122,69
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [Colors:Selection]
        BackgroundNormal=201,114,63
        BackgroundAlternate=176,95,50
        ForegroundNormal=255,246,236
        ForegroundInactive=245,225,205
        ForegroundActive=255,246,236
        ForegroundLink=255,225,200
        ForegroundVisited=240,210,190
        ForegroundNegative=255,205,195
        ForegroundNeutral=255,230,190
        ForegroundPositive=225,240,200
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [Colors:Tooltip]
        BackgroundNormal=74,59,66
        BackgroundAlternate=92,74,82
        ForegroundNormal=247,233,214
        ForegroundInactive=200,186,175
        ForegroundActive=227,168,118
        ForegroundLink=212,137,154
        ForegroundVisited=190,120,140
        ForegroundNegative=220,130,120
        ForegroundNeutral=230,180,110
        ForegroundPositive=170,195,140
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [Colors:Complementary]
        BackgroundNormal=140,90,107
        BackgroundAlternate=122,74,92
        ForegroundNormal=252,245,234
        ForegroundInactive=225,205,210
        ForegroundActive=237,209,174
        ForegroundLink=245,200,215
        ForegroundVisited=225,180,195
        ForegroundNegative=240,160,150
        ForegroundNeutral=240,195,130
        ForegroundPositive=185,205,155
        DecorationFocus=227,168,118
        DecorationHover=237,209,174

        [Colors:Header]
        BackgroundNormal=237,209,174
        BackgroundAlternate=227,168,118
        ForegroundNormal=74,59,66
        ForegroundInactive=122,107,112
        ForegroundActive=201,114,63
        ForegroundLink=140,90,107
        ForegroundVisited=122,74,92
        ForegroundNegative=176,75,63
        ForegroundNeutral=201,132,63
        ForegroundPositive=95,122,69
        DecorationFocus=201,114,63
        DecorationHover=227,168,118

        [WM]
        activeBackground=237,209,174
        activeForeground=74,59,66
        activeBlend=201,114,63
        inactiveBackground=247,233,214
        inactiveForeground=122,107,112
        inactiveBlend=237,209,174
      '';

      # Breeze-GTK does not read kdeglobals unless kde-gtk-config is running,
      # which it is not outside Plasma, so recolour GTK explicitly.
      gtk3Css = ''
        @define-color theme_bg_color #f7e9d6;
        @define-color theme_base_color #fcf5ea;
        @define-color theme_fg_color #4a3b42;
        @define-color theme_text_color #4a3b42;
        @define-color theme_selected_bg_color #c9723f;
        @define-color theme_selected_fg_color #fff6ec;
        @define-color insensitive_bg_color #f1e0c9;
        @define-color insensitive_fg_color #7a6b70;
        @define-color insensitive_base_color #f7e9d6;
        @define-color theme_unfocused_bg_color #f7e9d6;
        @define-color theme_unfocused_base_color #fcf5ea;
        @define-color theme_unfocused_fg_color #4a3b42;
        @define-color theme_unfocused_text_color #4a3b42;
        @define-color theme_unfocused_selected_bg_color #ddb08a;
        @define-color theme_unfocused_selected_fg_color #4a3b42;
        @define-color borders #ddc4a4;
        @define-color unfocused_borders #e6d3ba;
        @define-color warning_color #c9843f;
        @define-color error_color #b04b3f;
        @define-color success_color #5f7a45;
        @define-color link_color #8c5a6b;
        @define-color visited_link_color #7a4a5c;
      '';

      gtk4Css = ''
        @define-color window_bg_color #f7e9d6;
        @define-color window_fg_color #4a3b42;
        @define-color view_bg_color #fcf5ea;
        @define-color view_fg_color #4a3b42;
        @define-color headerbar_bg_color #edd1ae;
        @define-color headerbar_fg_color #4a3b42;
        @define-color headerbar_border_color #4a3b42;
        @define-color headerbar_backdrop_color #f1e0c9;
        @define-color sidebar_bg_color #f1e0c9;
        @define-color sidebar_fg_color #4a3b42;
        @define-color sidebar_backdrop_color #f7e9d6;
        @define-color secondary_sidebar_bg_color #f4e5d0;
        @define-color secondary_sidebar_fg_color #4a3b42;
        @define-color card_bg_color #fcf5ea;
        @define-color card_fg_color #4a3b42;
        @define-color dialog_bg_color #f7e9d6;
        @define-color dialog_fg_color #4a3b42;
        @define-color popover_bg_color #fcf5ea;
        @define-color popover_fg_color #4a3b42;
        @define-color accent_bg_color #c9723f;
        @define-color accent_fg_color #fff6ec;
        @define-color accent_color #a85a2c;
        @define-color destructive_bg_color #b04b3f;
        @define-color destructive_fg_color #fff6ec;
        @define-color destructive_color #9c3f34;
        @define-color success_bg_color #5f7a45;
        @define-color success_fg_color #fcf5ea;
        @define-color success_color #4f6738;
        @define-color warning_bg_color #c9843f;
        @define-color warning_fg_color #4a3b42;
        @define-color warning_color #a86a2c;
        @define-color error_bg_color #b04b3f;
        @define-color error_fg_color #fff6ec;
        @define-color error_color #9c3f34;
      '';

      gtkSettings = ''
        [Settings]
        gtk-application-prefer-dark-theme=0
        gtk-theme-name=Breeze
        gtk-icon-theme-name=Papirus-Light
        gtk-cursor-theme-name=breeze_cursors
        gtk-cursor-theme-size=24
      '';
    in
    {
      qt = {
        enable = true;
        platformTheme = "kde";
        style = "breeze";
      };

      environment.etc = {
        "xdg/color-schemes/WindmillLight.colors".source = colorScheme;
        "xdg/kdeglobals".source = colorScheme;

        "xdg/gtk-3.0/settings.ini".text = gtkSettings;
        "xdg/gtk-4.0/settings.ini".text = gtkSettings;
        "xdg/gtk-3.0/gtk.css".text = gtk3Css;
        "xdg/gtk-4.0/gtk.css".text = gtk4Css;
      };

      programs.dconf.enable = true;

      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-light";
            gtk-theme = "Breeze";
            icon-theme = "Papirus-Light";
            cursor-theme = "breeze_cursors";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.niri = {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Settings" = [
            "gnome"
            "gtk"
          ];
        };
      };

      environment.systemPackages = [
        pkgs.papirus-icon-theme
        pkgs.kdePackages.breeze
        pkgs.kdePackages.breeze-gtk
        pkgs.kdePackages.breeze-icons
        pkgs.kdePackages.qtwayland
        pkgs.kdePackages.dolphin
        pkgs.kdePackages.kio-extras
      ];
    };
}