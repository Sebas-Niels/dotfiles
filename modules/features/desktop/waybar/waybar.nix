{ self, ... }: {
  flake.nixosModules.waybar = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureWaybar
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
      networkStatus = pkgs.writeShellApplication {
        name = "waybar-network";
        runtimeInputs = with pkgs; [
          iproute2
          iw
          curl
          jq
          gawk
          gnused
        ];
        text = ''
          dev=$(ip route show default | awk '{ print $5; exit }')
          if [ -z "$dev" ]; then
            jq -nc '{ text: "󰲛", class: "offline", tooltip: "offline: no default route" }'
            exit
          fi

          if [ -d "/sys/class/net/$dev/wireless" ]; then
            icon=󰖩
            link="$(iw dev "$dev" link | sed -n 's/^\s*SSID: //p')"
          else
            icon=󰈀
            link=ethernet
          fi
          addr=$(ip -4 -br addr show dev "$dev" | awk '{ print $3 }')

          if curl -fsS -o /dev/null --max-time 4 https://one.one.one.one/cdn-cgi/trace 2>/dev/null; then
            state=online
          else
            state="no internet"
            icon=󰲛
          fi
          jq -nc --arg text "$icon" --arg class "''${state// /-}" \
            --arg tooltip "$state: $link on $dev $addr" '{ $text, $class, $tooltip }'
        '';
      };

      waybarConfig = (pkgs.formats.json { }).generate "waybar-config.json" {
        layer = "top";
        position = "top";
        height = 44;
        spacing = 6;

        modules-left = [ "ext/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "custom/network"
          "cpu"
          "memory"
          "disk#root"
          "disk#games"
          "tray"
        ];

        "ext/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-id = true;
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "{:%Y-%m-%d}";
        };

        pulseaudio = {
          format = "vol {volume}%";
          format-muted = "muted";
          on-click = "mmsg dispatch 'toggle_named_scratchpad,com\\.saivert\\.pwvucontrol,none,${lib.getExe pkgs.pwvucontrol}'";
          on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        "custom/network" = {
          exec = lib.getExe networkStatus;
          return-type = "json";
          interval = 10;
        };

        cpu.format = "cpu {usage}%";
        memory.format = "mem {percentage}%";

        "disk#root" = {
          path = "/";
          format = "/ {percentage_used}%";
          tooltip-format = "{path}: {used} used, {free} free of {total}";
          states.critical = 90;
        };
        "disk#games" = {
          path = "/mnt/games";
          format = "games {percentage_used}%";
          tooltip-format = "{path}: {used} used, {free} free of {total}";
          states.critical = 90;
        };

        tray.spacing = 12;
      };

      waybarStyle =
        t:
        lib.concatStrings (lib.mapAttrsToList (name: hex: "@define-color ${name} ${hex};\n") t.c)
        + "\n"
        + builtins.readFile ./style.css;

      waybar = pkgs.writeShellScript "waybar" ''
        ${lib.getExe self'.packages.apertureTheme} init
        start_bar() {
          ${lib.getExe pkgs.waybar} -c ${waybarConfig} \
            -s "$HOME/.local/state/aperture-theme/current/waybar.css" "$@" &
          bar=$!
        }
        start_bar "$@"

        trap 'kill "$bar" 2>/dev/null' EXIT
        trap ':' USR2

        self=$(${pkgs.coreutils}/bin/readlink -f "$0")
        css="$HOME/.local/state/aperture-theme/current/waybar.css"
        style=$(${pkgs.coreutils}/bin/readlink -f "$css") || true
        while :; do
          ${pkgs.coreutils}/bin/sleep 3
          if ! kill -0 "$bar" 2>/dev/null; then
            status=0
            wait "$bar" || status=$?
            [ "$status" -eq 0 ] && exit
            [ -S "$XDG_RUNTIME_DIR/''${WAYLAND_DISPLAY:-wayland-0}" ] || exit
            start_bar "$@"
            continue
          fi
          installed=$(${pkgs.coreutils}/bin/readlink -f /run/current-system/sw/bin/waybar) || continue
          if [ "$installed" != "$self" ]; then
            kill "$bar"
            wait "$bar" 2>/dev/null
            trap - EXIT
            exec /run/current-system/sw/bin/waybar "$@"
          fi
          current=$(${pkgs.coreutils}/bin/readlink -f "$css") || continue
          if [ "$current" != "$style" ]; then
            style=$current
            kill -USR2 "$bar" 2>/dev/null || true
          fi
        done
      '';
    in
    {
      apertureTheme.targets."waybar.css" = waybarStyle;

      packages.apertureWaybar = pkgs.symlinkJoin {
        name = "aperture-waybar";
        paths = [ pkgs.waybar ];
        postBuild = ''
          rm $out/bin/waybar
          ln -s ${waybar} $out/bin/waybar
        '';
        meta.mainProgram = "waybar";
      };
    };
}
