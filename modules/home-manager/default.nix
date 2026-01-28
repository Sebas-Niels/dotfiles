{ config, inputs, pkgs, ... }:
{
    imports = [
        ./programs
        ./wayland
    ];
}
