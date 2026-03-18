{ pkgs, ... }:
{
  home.packages.godot = with pkgs; {
    enable = true;
  };
}