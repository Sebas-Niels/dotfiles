{ config, inputs, pkgs, username, ... }:
{
    imports = [
        #./librewolf.nix
        #./firefox.nix
    ];


    programs = {
      firefox = {
        enable = true;
        #profiles.${username} = {};
      };
    };
}
