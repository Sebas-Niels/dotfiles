{ ... }:
{
  flake.nixosModules.darkTheming =
    { pkgs, lib, ... }:
    {
      qt = {
        enable = true;
        platformTheme = "kde";
        style = "breeze";
      };

      environment.etc."xdg/kdeglobals".source = pkgs.runCommand "kdeglobals" { } ''
        cat ${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors > $out
        printf '\n[Icons]\nTheme=Papirus-Dark\n' >> $out
        printf '\n[KDE]\nwidgetStyle=Breeze\n' >> $out
      '';

      environment.etc."xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Breeze-Dark
        gtk-icon-theme-name=Papirus-Dark
        gtk-cursor-theme-name=breeze_cursors
        gtk-cursor-theme-size=24
      '';

      environment.etc."xdg/gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Breeze-Dark
        gtk-icon-theme-name=Papirus-Dark
        gtk-cursor-theme-name=breeze_cursors
        gtk-cursor-theme-size=24
      '';

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