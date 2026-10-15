{ self, inputs, ... }:
{
  flake.nixosModules.ghostty =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureGhostty
      ];
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      # Same theme as kitty, by its kitty-themes file name (see the list in kitty.nix).
      # Ghostty doesn't ship most of these, so the kitty theme is converted to Ghostty's format.
      kittyTheme = "moonlight";

      theme = pkgs.runCommand "ghostty-theme-${kittyTheme}" { } ''
        ${lib.getExe pkgs.gawk} '
          $2 !~ /^#/ { next }
          $1 == "foreground" || $1 == "background" { print $1 " = " $2 }
          $1 == "selection_foreground" { print "selection-foreground = " $2 }
          $1 == "selection_background" { print "selection-background = " $2 }
          $1 == "cursor" { print "cursor-color = " $2 }
          $1 == "cursor_text_color" { print "cursor-text = " $2 }
          $1 ~ /^color[0-9]+$/ { print "palette = " substr($1, 6) "=" $2 }
        ' ${pkgs.kitty-themes}/share/kitty-themes/themes/${kittyTheme}.conf > $out
      '';
    in
    {
      packages.apertureGhostty = inputs.wrapper-modules.wrappers.ghostty.wrap {
        inherit pkgs;

        settings = {
          font-family = "JetBrainsMono Nerd Font";
          font-size = 16;
          theme = "${theme}";
          background-opacity = 0.75;
          background-blur = 64;
          command = lib.getExe self'.packages.apertureZsh;
          # Close without asking, even with a program still running
          confirm-close-surface = false;
        };
      };
    };
}
