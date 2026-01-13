{ config, pkgs, lib, ... }:

{
  systemd.user.services.silent-sound = {
    Unit = {
      Description = "Silent Sound Service script for audeze maxwell x, prevent startup delay during standby";
      After = [ "sound.target" ];
    };

    Service = {
      ExecStart =
        "${pkgs.ffmpeg}/bin/ffplay -f lavfi -i anullsrc=channel_layout=2:sample_rate=48000 -nodisp -loglevel quiet";
      Restart = "always";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
