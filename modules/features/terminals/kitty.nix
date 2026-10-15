{ self, inputs, ... }:
{
  flake.nixosModules.kitty =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureKitty
      ];
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      # Colours come from the theme menu (see theme-menu.nix)
      apertureTheme.targets."kitty.conf" = t: ''
        foreground ${t.c.text}
        background ${t.c.bg}
        selection_foreground ${t.c.text}
        selection_background ${t.term.selection}
        cursor ${t.term.cursor}
        cursor_text_color ${t.c.bg}
        url_color ${t.c.accent}
        active_border_color ${t.c.accent}
        inactive_border_color ${t.c.overlay}
        active_tab_foreground ${t.c.bg}
        active_tab_background ${t.c.accent}
        inactive_tab_foreground ${t.c.subtext}
        inactive_tab_background ${t.c.mantle}
        tab_bar_background ${t.c.mantle}
        ${lib.concatImapStringsSep "\n" (i: color: "color${toString (i - 1)} ${color}") t.ansi}
      '';

      packages.apertureKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;

        font = {
          name = "JetBrainsMono Nerd Font";
          size = 16.0;
        };

        settings = {
          background_opacity = "0.75";
          background_blur = "64";
          shell = lib.getExe self'.packages.apertureZsh;
        };

        # kitty skips a missing include, so this is safe before a theme has been picked
        extraConfig = ''
          include ~/.local/state/aperture-theme/current/kitty.conf
        '';
      };
    };
}
