{ config, inputs, pkgs, ... }:
{
    imports = [
        ./dunst.nix
        ./rofi.nix
        ./yazi.nix
        #./keyring.nix
    ];
}
