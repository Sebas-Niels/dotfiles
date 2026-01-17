{ config, lib, ... }:

{
  xdg.configFile."wireplumber/wireplumber.conf.d/99-prefer-audeze.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "~alsa_output.usb-Audeze_LLC_Audeze_Maxwell.*analog-stereo"
          }
        ]
        actions = {
          update-props = {
            priority.session = 2000
            priority.driver = 2000
          }
        }
      }
    ]
  '';
}
