{ pkgs, ... }:

{
  systemd.user.services.audeze-keepalive = {
    Unit = {
      Description = "Audeze Maxwell keepalive (PulseAudio paplay)";
      After = [ "pipewire-pulse.service" ];
    };

    Service = {
      ExecStart = ''
        ${pkgs.pulseaudio}/bin/paplay \
          --volume=2000 \
          /run/current-system/sw/share/sounds/freedesktop/stereo/silence.oga
      '';
      Restart = "always";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
