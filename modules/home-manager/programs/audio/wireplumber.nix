{ pkgs, ... }:

{
  ############################################
  # WirePlumber rules
  ############################################

  home.file.".config/wireplumber/main.lua.d/40-discord-streams.lua".text = ''
    -- Prevent Discord audio streams from suspending on idle
    local discord_rule = {
      matches = {
        {
          { "application.process.binary", "matches", ".*Discord.*" },
        },
      },
      apply_properties = {
        ["node.suspend-on-idle"] = false,
      },
    }

    table.insert(stream.rules, discord_rule)
  '';

  home.file.".config/wireplumber/main.lua.d/90-audeze-noise.lua".text = ''
    -- Inject very low-level noise to keep Audeze Maxwell awake
    table.insert(alsa_monitor.rules, {
      matches = {
        {
          { "node.name", "equals", "audeze.keepalive.source" },
        },
      },
      apply_properties = {
        ["node.noise"] = true,
        ["node.noise.level"] = -60.0,
      },
    })
  '';

  ############################################
  # Audeze keepalive PipeWire service
  ############################################

  systemd.user.services.audeze-keepalive = {
    Unit = {
      Description = "Keep Audeze Maxwell awake (inaudible noise keepalive)";
      After = [ "pipewire.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "wireplumber.service" ];
    };

    Service = {
      ExecStart = ''
        ${pkgs.pipewire}/bin/pw-loopback \
          --capture-props='media.class=Audio/Source,node.name=audeze.keepalive.source,audio.rate=48000' \
          --playback-props='media.class=Audio/Sink,node.name=audeze.keepalive.sink' \
          --channels=2 \
          --format=f32
      '';
      Restart = "always";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
