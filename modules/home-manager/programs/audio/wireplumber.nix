{ config, pkgs, ... }:

{
  xdg.configFile."wireplumber/main.lua.d/51-disable-suspend.lua".text = ''

  '';

}
