{ self, inputs, ... }: {

  flake.nixosModules.flatpakGames = { pkgs, ... }:
  let
    games = [
      "com.adamcake.Bolt" # Bolt launcher (Jagex launcher for RuneScape/OSRS)
    ];
  in {
    services.flatpak.enable = true;

    # Extra system installation on the games drive: flatpak install --installation=games flathub <app>
    environment.etc."flatpak/installations.d/games.conf".text = ''
      [Installation "games"]
      Path=/mnt/games/flatpak
      DisplayName=Games
      StorageType=harddisk
    '';

    # Make installed games visible to app launchers
    environment.sessionVariables.XDG_DATA_DIRS = [ "/mnt/games/flatpak/exports/share" ];

    # Steam launch options for OSRS: osrs-bolt %command%
    # Ignores Steam's command and runs Bolt instead, blocking until it exits so playtime is tracked.
    # Bolt runs as a user unit to escape Steam's FHS sandbox and environment.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "osrs-bolt" ''
        env_args=()
        for var in DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do
          [ -n "''${!var}" ] && env_args+=("--setenv=$var=''${!var}")
        done

        trap 'systemctl --user stop osrs-bolt.service' INT TERM

        systemd-run --user --wait --collect --unit=osrs-bolt "''${env_args[@]}" \
          ${pkgs.flatpak}/bin/flatpak run --installation=games com.adamcake.Bolt &
        wait $!
      '')
    ];

    systemd.services.flatpak-games = {
      description = "Set up flathub and install games in the games flatpak installation";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = "/mnt/games";
      path = [ pkgs.flatpak ];
      serviceConfig.Type = "oneshot";
      script = ''
        flatpak remote-add --installation=games --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --installation=games --noninteractive --or-update flathub ${toString games}
        # Java/AWT renders at its initial size under non-reparenting WMs (RuneLite stuck on the left)
        flatpak override --installation=games --env=_JAVA_AWT_WM_NONREPARENTING=1 com.adamcake.Bolt
      '';
    };
  };
}
