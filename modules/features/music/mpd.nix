{ ... }:
let
  user = "nivis";
in
{
  # The music server; clients (rmpc, mpc) connect over its socket, /run/mpd/socket
  flake.nixosModules.mpd =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.mpc ];

      services.mpd = {
        enable = true;
        inherit user;
        openFirewall = false;
        settings = {
          music_directory = "/home/${user}/Music/music_directory";
          bind_to_address = "/run/mpd/socket";
          auto_update = true;
          audio_output = [
            {
              type = "pulse";
              name = "PipeWire PulseAudio";
            }
          ];
        };
      };

      systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/1000";
      users.users.${user}.linger = true;
    };
}
