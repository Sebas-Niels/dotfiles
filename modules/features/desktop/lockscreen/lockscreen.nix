{ self, ... }:
{
  # The lockscreen (CTRL+ALT+L): the current theme's wallpaper, blurred and dimmed, on every
  # monitor, with a clock and a password pill on the ultrawide. Drawn by quickshell over ext-session-lock, so
  # if it ever crashes mango keeps the session locked rather than showing the desktop.
  flake.nixosModules.lockscreen =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureLock
      ];

      # Checks the password against the user's own, like swaylock's did
      security.pam.services.aperture-lock = { };
    };

  perSystem =
    { pkgs, ... }:
    let
      lockConfig = pkgs.runCommand "aperture-lock-config" { } ''
        mkdir $out
        cp ${./shell.qml} $out/shell.qml
      '';
    in
    {
      apertureTheme.targets."lockscreen.json" =
        t:
        let
          inherit (t) c mix;
        in
        builtins.toJSON {
          inherit (c)
            mantle
            surface
            overlay
            accent
            accent2
            red
            ;
          # Drawn over a darkened wallpaper on every theme, so the text stays light even on
          # light themes, tinted towards the theme's own text
          text = if t.dark then c.text else mix c.bg "#ffffff" 0.6;
          subtext = if t.dark then c.subtext else mix c.subtext "#ffffff" 0.6;
          shade = if t.dark then c.mantle else mix c.text "#000000" 0.4;
        };

      # Locks the session until the password is typed; a second press while locked does nothing
      packages.apertureLock = pkgs.writeShellApplication {
        name = "aperture-lock";
        runtimeInputs = [ pkgs.quickshell ];
        text = ''
          exec quickshell -p ${lockConfig} --no-duplicate
        '';
      };
    };
}
