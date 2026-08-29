{ ... }: {
  flake.nixosModules.pipewireAudio = { pkgs, ... }: {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-suspend.conf" ''
          monitor.alsa.rules = [
            {
              matches = [
                {
                  device.name = "~alsa_card.*"
                }
              ]
              actions = {
                update-props = {
                  api.alsa.use-acp = true
                }
              }
            }
            {
              matches = [
                {
                  node.name = "~alsa_input.*"
                }
                {
                  node.name = "~alsa_output.*"
                }
              ]
              actions = {
                update-props = {
                  session.suspend-timeout-seconds = 0
                }
              }
            }
          ]
        '')
      ];
    };
  };
}
