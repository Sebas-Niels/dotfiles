{ self, inputs, ... }: {

  flake.nixosModules.flatpakGames =
    { pkgs, ... }:
    let
      games = [
        "com.adamcake.Bolt"
      ];
    in
    {
      services.flatpak.enable = true;

      environment.etc."flatpak/installations.d/games.conf".text = ''
        [Installation "games"]
        Path=/mnt/games/flatpak
        DisplayName=Games
        StorageType=harddisk
      '';

      environment.sessionVariables.XDG_DATA_DIRS = [ "/mnt/games/flatpak/exports/share" ];

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
          flatpak override --installation=games --env=_JAVA_AWT_WM_NONREPARENTING=1 com.adamcake.Bolt
        '';
      };
    };
}
