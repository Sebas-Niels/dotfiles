{ self, ... }:
{
  # A coin to flip, kept down the right of the Xeneon Edge: tap it (or `aperture-coinflip flip`)
  # to toss it, right click or long press to clear the tally. Drawn by quickshell in the
  # current theme's colours, the coin struck from its yellow.
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

      # aperture-coinflip [flip|reset|reload] drives the running coin; `daemon` starts it
      packages.apertureCoinflip = pkgs.writeShellApplication {
        name = "aperture-coinflip";
        runtimeInputs = [
          pkgs.quickshell
          pkgs.procps
          pkgs.gnugrep
        ];
        text = ''
          qs() { quickshell -p ${coinConfig} "$@"; }

          # Coins started from an earlier build keep running their old config; stop them so
          # only this build's coin is ever around
          pgrep -af 'quickshell.*aperture-coinflip-config' | grep -vF '${coinConfig}' \
            | while read -r pid _; do kill "$pid" 2>/dev/null || true; done || true

          action="''${1:-flip}"
          if [ "$action" = daemon ]; then
            exec quickshell -p ${coinConfig} --no-duplicate
          fi

          if ! qs ipc call coinflip "$action" >/dev/null 2>&1; then
            # Not running, or wedged: start it over
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
