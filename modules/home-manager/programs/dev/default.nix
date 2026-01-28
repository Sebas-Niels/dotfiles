{ config, inputs, pkgs, ... }:
{
    imports = [
        ./git.nix
        ./editors
    ];
}
