# This used to be the configuration.nix file, but is renamed to default.nix for flakes convention and convenience.
# Nix automatically imports the default.nix in a directory.

{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default

      # Bootloader
      ../../modules/nixos/boot/grub.nix

      # Time & Locale
      ../../modules/nixos/locale/locale.nix

      # X11 & Desktop environment
      ../../modules/nixos/desktop/plasma.nix

      # Printing
      ../../modules/nixos/printing.nix

      # Audio
      ../../modules/nixos/audio/pipewire.nix

      # Role Programs
      ../../modules/nixos/roles/workstation.nix

      # Nix Settings
      ../../modules/nixos/base.nix

      # User definition
      ../../users/nixos/user.nix

    ];

  # Define your hostname.
  networking.hostName = "vmware";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "nixos" = import ../../users/nixos/home.nix;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;


  # MOVE THIS TO THE APPROPRIATE VM HOST EVENTUALLY
  virtualisation.vmware.guest.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.11";

}
