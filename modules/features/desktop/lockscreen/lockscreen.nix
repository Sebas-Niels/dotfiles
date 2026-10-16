{ self, ... }:
{
  flake.nixosModules.lockscreen =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureLock
      ];

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
          text = if t.dark then c.text else mix c.bg "#ffffff" 0.6;
          subtext = if t.dark then c.subtext else mix c.subtext "#ffffff" 0.6;
          shade = if t.dark then c.mantle else mix c.text "#000000" 0.4;
        };

      packages.apertureLock = pkgs.writeShellApplication {
        name = "aperture-lock";
        runtimeInputs = [ pkgs.quickshell ];
        text = ''
          exec quickshell -p ${lockConfig} --no-duplicate
        '';
      };
    };
}
