{ self, ... }: {

  flake.nixosModules.brightnessSchedule = { pkgs, ... }:
    let
      brightnessSchedule = self.packages.${pkgs.stdenv.hostPlatform.system}.brightnessSchedule;
    in {
      environment.systemPackages = [ brightnessSchedule ];

      systemd.user.services.brightness-schedule = {
        description = "Set monitor brightness by time of day via Noctalia";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${brightnessSchedule}/bin/brightness-schedule";
        };
      };

      systemd.user.timers.brightness-schedule = {
        wantedBy = [ "graphical-session.target" ];
        timerConfig = {
          OnActiveSec = "15s";
          OnCalendar = "*:0/5";
          Persistent = true;
        };
      };
    };

  perSystem = { pkgs, self', ... }: {

    packages.brightnessSchedule = pkgs.writeShellApplication {
      name = "brightness-schedule";
      runtimeInputs = [ pkgs.coreutils self'.packages.lambdaNoctalia ];
      text = ''
        hour=$(date +%-H)

        # ---- your schedule (percent) ----
        if   (( hour >= 21 || hour < 9 )); then target=5
        elif (( hour >= 19 ));             then target=30
        else                                    target=50
        fi

        # Apply once per period so manual slider changes aren't overridden
        state="''${XDG_RUNTIME_DIR:-/tmp}/brightness-schedule"
        if [[ -f "$state" && "$(cat "$state")" == "$target" ]]; then
          exit 0
        fi

        # Fails if Noctalia isn't running yet; state isn't written, so it retries
        noctalia-shell ipc call brightness set "$target"

        echo "$target" > "$state"
      '';
    };
  };
}