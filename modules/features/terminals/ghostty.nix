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
    {
      apertureTheme.targets."ghostty" = t: ''
        background = ${t.c.bg}
        foreground = ${t.c.text}
        selection-background = ${t.term.selection}
        selection-foreground = ${t.c.text}
        cursor-color = ${t.term.cursor}
        cursor-text = ${t.c.bg}
        ${lib.concatImapStringsSep "\n" (i: color: "palette = ${toString (i - 1)}=${color}") t.ansi}
      '';

      packages.apertureGhostty = inputs.wrapper-modules.wrappers.ghostty.wrap {
        inherit pkgs;

        settings = {
          font-family = "JetBrainsMono Nerd Font";
          font-size = 16;
          config-file = "?~/.local/state/aperture-theme/current/ghostty";
          background-opacity = 0.75;
          background-blur = 64;
          command = lib.getExe self'.packages.apertureZsh;
          confirm-close-surface = false;
        };
      };
    };
}
