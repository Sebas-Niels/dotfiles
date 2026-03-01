{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rmpc
    mpc
  ];

  xdg.configFile."rmpc/config.ron".text = ''
(
  address: "/run/user/1000/mpd.socket",
)
'';

  services.mpd = {
    enable = true;

    musicDirectory = "/home/nivis/Music/music_directory";

    extraConfig = ''
      bind_to_address "/run/user/1000/mpd.socket"
      auto_update "yes"

      audio_output {
        type "pulse"
        name "PipeWire PulseAudio"
      }
    '';
  };
}
