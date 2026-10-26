{ self, ... }:
{
  flake.nixosModules.displayMenu =
    { pkgs, ... }:
    {
      environment.systemPackages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
        apertureDisplay
        apertureDisplayDaemon
        apertureDisplayMenu
      ];
    };

  perSystem =
    { pkgs, lib, ... }:
    let
      # Brightness goes to every monitor over DDC/CI; the night filter is a gamma ramp
      # applied by wl-gammarelay-rs, which has to be running (mango starts it).
      displayScript = pkgs.writeShellApplication {
        name = "aperture-display";
        runtimeInputs = with pkgs; [
          coreutils
          gawk
          ddcutil
          systemd
        ];
        text = ''
          state="$HOME/.local/state/aperture-display"
          buses="''${XDG_RUNTIME_DIR:-/tmp}/aperture-display-buses"

          get() {
            local value
            value=$(cat "$state/$1" 2>/dev/null) || true
            echo "''${value:-$2}"
          }

          put() {
            mkdir -p "$state"
            echo "$2" > "$state/$1"
          }

          # Detecting monitors takes about a second, so the I2C buses are cached per session
          detect() {
            ddcutil detect --terse \
              | awk '/^Display/ { ok = 1 } /^Invalid/ { ok = 0 } ok && /I2C bus/ { sub("/dev/i2c-", "", $3); print $3 }' \
              > "$buses.$$"
            mv -f "$buses.$$" "$buses"
          }

          # Shorter DDC sleeps and no startup probing take a set from ~0.75s to ~0.25s
          brightness() {
            [ -s "$buses" ] || detect
            local bus list failed=0
            mapfile -t list < "$buses"
            for bus in "''${list[@]}"; do
              ddcutil --bus "$bus" --noverify --sleep-multiplier .2 --skip-ddc-checks setvcp 10 "$1" &
            done
            for _ in "''${list[@]}"; do
              wait -n || failed=1
            done
            if [ "$failed" = 1 ]; then
              rm -f "$buses"
            fi
          }

          temperature() {
            for _ in $(seq 50); do
              busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$1" 2>/dev/null && return
              sleep 0.1
            done
            echo "aperture-display: wl-gammarelay-rs is not running" >&2
            return 1
          }

          night() {
            if [ "$(get night off)" = on ]; then
              temperature "$(get warmth 3500)"
            else
              temperature 6500
            fi
          }

          minutes() {
            local h=''${1%%:*} m=''${1##*:}
            echo $((10#$h * 60 + 10#$m))
          }

          now() {
            minutes "$(date +%H:%M)"
          }

          clock() {
            [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
          }

          # Brightness points, one "HH:MM percent" per line, sorted by time
          points() {
            if [ ! -e "$state/points" ]; then
              mkdir -p "$state"
              printf '07:00 40\n20:00 25\n22:30 15\n' > "$state/points"
            fi
            cat "$state/points"
          }

          # The latest point at or before now; before the first one, yesterday's last still holds
          point() {
            local t level at current best="" last=""
            current=$(now)
            while read -r t level; do
              last="$t $level"
              at=$(minutes "$t")
              if [ "$at" -le "$current" ]; then
                best="$t $level"
              fi
            done < <(points)
            echo "''${best:-$last}"
          }

          # Whether the night light should be on; the on-window may wrap past midnight
          period() {
            local current start end
            current=$(now)
            start=$(minutes "$(get night-on 21:30)")
            end=$(minutes "$(get night-off 07:00)")
            if [ "$start" -le "$end" ]; then
              if [ "$current" -ge "$start" ] && [ "$current" -lt "$end" ]; then echo night; else echo day; fi
            else
              if [ "$current" -ge "$start" ] || [ "$current" -lt "$end" ]; then echo night; else echo day; fi
            fi
          }

          # The two schedules are independent; both used to share one "schedule" switch
          scheduled() {
            [ "$(get "$1-schedule" "$(get schedule off)")" = on ]
          }

          # Only acts when the period or point changes, so a schedule switched back on picks up
          # where it is. Editing the active point counts as a change, so it applies right away.
          tick() {
            local p pt
            if scheduled night; then
              p=$(period)
              if [ "$p" != "$(get period "")" ]; then
                put period "$p"
                put night "$([ "$p" = night ] && echo on || echo off)"
                night &
              fi
            fi
            if scheduled brightness; then
              pt=$(point)
              if [ -n "$pt" ] && [ "$pt" != "$(get point "")" ]; then
                put point "$pt"
                put brightness "''${pt#* }"
                brightness "''${pt#* }"
              fi
            fi
            wait
          }

          bool() {
            if [ "$(get "$1" off)" = on ]; then echo true; else echo false; fi
          }

          # Manual changes switch the matching schedule off rather than fighting it
          unschedule() {
            put "$1-schedule" off
          }

          case "''${1:-}" in
            status)
              printf '{"brightness":%s,"night":%s,"warmth":%s,"brightnessSchedule":%s,"nightSchedule":%s,"nightOn":"%s","nightOff":"%s","activePoint":"%s","points":%s,"relay":%s}\n' \
                "$(get brightness 30)" \
                "$(bool night)" \
                "$(get warmth 3500)" \
                "$(scheduled brightness && echo true || echo false)" \
                "$(scheduled night && echo true || echo false)" \
                "$(get night-on 21:30)" \
                "$(get night-off 07:00)" \
                "$(point | cut -d' ' -f1)" \
                "$(points | awk 'BEGIN { printf "[" } { printf "%s{\"time\":\"%s\",\"brightness\":%s}", (NR > 1 ? "," : ""), $1, $2 } END { printf "]" }')" \
                "$(busctl --user status rs.wl-gammarelay &>/dev/null && echo true || echo false)"
              ;;
            schedule)
              kind="''${2:-}"
              case "$kind:''${3:-}" in
                brightness: | night:)
                  scheduled "$kind" && echo on || echo off
                  ;;
                brightness:on | night:on)
                  put "$kind-schedule" on
                  if [ "$kind" = night ]; then rm -f "$state/period"; else rm -f "$state/point"; fi
                  tick
                  ;;
                brightness:off | night:off)
                  put "$kind-schedule" off
                  ;;
                night:window)
                  if ! clock "''${4:-}" || ! clock "''${5:-}"; then
                    echo "aperture-display: schedule night window takes <on HH:MM> <off HH:MM>" >&2
                    exit 1
                  fi
                  put night-on "$4"
                  put night-off "$5"
                  tick
                  ;;
                brightness:points)
                  shift 3
                  for p in "$@"; do
                    if ! clock "''${p%=*}" || ! [[ "''${p#*=}" =~ ^[0-9]+$ ]]; then
                      echo "aperture-display: points are HH:MM=<percent>, got $p" >&2
                      exit 1
                    fi
                  done
                  mkdir -p "$state"
                  for p in "$@"; do
                    echo "''${p%=*} ''${p#*=}"
                  done | sort > "$state/points.$$"
                  mv -f "$state/points.$$" "$state/points"
                  tick
                  ;;
                *)
                  echo "aperture-display: schedule takes brightness [on | off | points HH:MM=<percent> ...]" >&2
                  echo "                  or night [on | off | window <on HH:MM> <off HH:MM>]" >&2
                  exit 1
                  ;;
              esac
              ;;
            brightness)
              if [ -z "''${2:-}" ]; then
                get brightness 30
              else
                unschedule brightness
                put brightness "$2"
                brightness "$2"
              fi
              ;;
            night)
              case "''${2:-}" in
                on | off) put night "$2" ;;
                toggle) put night "$([ "$(get night off)" = on ] && echo off || echo on)" ;;
                "") get night off; exit ;;
                *)
                  echo "aperture-display: night takes on | off | toggle" >&2
                  exit 1
                  ;;
              esac
              unschedule night
              if [ -n "''${3:-}" ]; then
                put warmth "$3"
              fi
              night
              ;;
            warmth)
              put warmth "$2"
              if [ "$(get night off)" = on ]; then
                temperature "$2"
              fi
              ;;
            reapply)
              night
              ;;
            restore)
              detect
              brightness "$(get brightness 30)" &
              night
              wait
              ;;
            watch)
              "$0" restore || true
              tick || true
              while sleep 20; do
                [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || exit 0
                tick || true
              done
              ;;
            *)
              echo "usage: aperture-display status | brightness [percent] | night [on|off|toggle] [kelvin] | warmth <kelvin>" >&2
              echo "       | schedule brightness [on|off | points HH:MM=<percent> ...] | schedule night [on|off | window <on> <off>] | restore | watch" >&2
              exit 1
              ;;
          esac
        '';
      };

      # Runs the schedule and wl-gammarelay-rs. Only one instance holds the lock, so the menu can
      # start it whenever it finds the night light daemon missing. The tint resets whenever
      # wl-gammarelay-rs exits, so it is restarted and the night light reapplied.
      displayDaemon = pkgs.writeShellApplication {
        name = "aperture-display-daemon";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        text = ''
          exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/aperture-display-daemon.lock"
          flock -n 9 || exit 0

          # Helpers don't inherit the lock, or their leftover children would hold it after a crash
          ${lib.getExe displayScript} watch 9>&- &
          while :; do
            ${lib.getExe displayScript} reapply 9>&- &
            ${lib.getExe pkgs.wl-gammarelay-rs} run || true
            [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || exit 0
            sleep 1
          done
        '';
      };

      menuConfig = pkgs.runCommand "aperture-display-menu-config" { } ''
        mkdir $out
        cp ${
          pkgs.replaceVars ./shell.qml {
            displayScript = lib.getExe displayScript;
            displayDaemon = lib.getExe displayDaemon;
          }
        } $out/shell.qml
        cp ${./Slider.qml} $out/Slider.qml
        cp ${./Toggle.qml} $out/Toggle.qml
        cp ${./TimeField.qml} $out/TimeField.qml
      '';
    in
    {
      apertureTheme.targets."display-menu.json" =
        t:
        builtins.toJSON {
          inherit (t.c)
            bg
            mantle
            surface
            overlay
            text
            subtext
            accent
            ;
          warm = t.c.yellow;
        };

      packages.apertureDisplay = displayScript;

      packages.apertureDisplayDaemon = displayDaemon;

      packages.apertureDisplayMenu = pkgs.writeShellApplication {
        name = "aperture-display-menu";
        runtimeInputs = [
          pkgs.quickshell
          pkgs.procps
          pkgs.gnugrep
        ];
        text = ''
          qs() { quickshell -p ${menuConfig} "$@"; }

          pgrep -af 'quickshell.*aperture-display-menu-config' | grep -vF '${menuConfig}' \
            | while read -r pid _; do kill "$pid" 2>/dev/null || true; done || true

          action="''${1:-toggle}"
          if [ "$action" = daemon ]; then
            exec quickshell -p ${menuConfig} --no-duplicate
          fi

          if ! qs ipc call display "$action" >/dev/null 2>&1; then
            pkill -f '${menuConfig}' || true
            qs --no-duplicate --daemonize
            for _ in $(seq 30); do
              qs ipc call display "$action" >/dev/null 2>&1 && exit 0
              sleep 0.1
            done
            exit 1
          fi
        '';
      };
    };
}
