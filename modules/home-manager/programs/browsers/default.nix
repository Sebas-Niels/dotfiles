{ config, inputs, pkgs, username, ... }:
{
    imports = [
        ./librewolf.nix
        ./tor.nix
        ./brave.nix
    ];
}
