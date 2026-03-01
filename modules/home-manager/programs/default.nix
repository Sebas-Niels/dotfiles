{ config, inputs, pkgs, ... }:
{
    imports = [
        ./adminutil
        ./audio
        ./browsers
        ./desktop
        ./dev
        ./game
        ./messaging
        ./terminals
        ./music
    ];
}
