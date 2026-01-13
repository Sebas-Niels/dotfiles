# Includes modules or common programs needed for this role, not defined by the users configuration

{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    speedtest-cli
    fastfetch

  ];


  # Install firefox.
  programs.firefox.enable = true;
}
