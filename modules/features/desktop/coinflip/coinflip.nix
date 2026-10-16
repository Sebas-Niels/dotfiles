{ self, ... }:
{
  flake.nixosModules.coinflip =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureCoinflip
      ];
    };

  perSystem =
    { pkgs, ... }:
    let
      coinConfig = pkgs.runCommand "aperture-coinflip-config" { } ''
        mkdir $out
        cp ${./shell.qml} $out/shell.qml
        cp ${./Coin.qml} $out/Coin.qml
        cp ${./Face.qml} $out/Face.qml
        cp ${./Glow.qml} $out/Glow.qml
      '';
    in
    {
      apertureTheme.targets."coinflip.json" =
        t:
        let
          inherit (t) c mix;
        in
        builtins.toJSON {
          inherit (c)
            bg
            mantle
            surface
            overlay
            text
            subtext
            accent
            ;
          metal = c.yellow;
          metalLight = mix c.yellow "#ffffff" 0.55;
          metalDark = mix c.yellow "#000000" 0.35;
          rim = mix c.yellow "#000000" 0.5;
        };

      packages.apertureCoinflip = pkgs.writeShellApplication {
        name = "aperture-coinflip";
        runtimeInputs = [
          pkgs.quickshell
          pkgs.procps
          pkgs.gnugrep
        ];
        text = ''
          qs() { quickshell -p ${coinConfig} "$@"; }

          pgrep -af 'quickshell.*aperture-coinflip-config' | grep -vF '${coinConfig}' \
            | while read -r pid _; do kill "$pid" 2>/dev/null || true; done || true

          action="''${1:-flip}"
          if [ "$action" = daemon ]; then
            exec quickshell -p ${coinConfig} --no-duplicate
          fi

          if ! qs ipc call coinflip "$action" >/dev/null 2>&1; then
            pkill -f '${coinConfig}' || true
            qs --no-duplicate --daemonize
            for _ in $(seq 30); do
              qs ipc call coinflip "$action" >/dev/null 2>&1 && exit 0
              sleep 0.1
            done
            exit 1
          fi
        '';
      };
    };
}
