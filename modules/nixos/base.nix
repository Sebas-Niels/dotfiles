{ pkgs, ... }:
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.kernel.sysctl."kernel.printk" = "3 3 3 3";
}
