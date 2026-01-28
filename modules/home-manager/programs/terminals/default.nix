{ config, inputs, pkgs, ... }:
{
    imports = [
        ./kitty.nix
        ./ghostty.nix
    ];
}
