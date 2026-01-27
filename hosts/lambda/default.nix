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
      ../../modules/nixos/desktop/hyprland.nix

      # Printing
      ../../modules/nixos/printing.nix

      # Audio
      ../../modules/nixos/audio/pipewire.nix

      # Role Programs
      ../../modules/nixos/roles/workstation.nix

      # Nix Settings
      ../../modules/nixos/base.nix

      # Virtualisation
      ../../modules/nixos/virtualisation/kvm_qemu.nix


      # User definition
      ../../users/nixtest/user.nix
      ../../users/nivis/user.nix

      #../../modules/home-manager/programs/steam.nix

    ];

  # Define your hostname.
  networking.hostName = "lambda";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "nixtest" = import ../../users/nixtest/home.nix;
      "nivis" = import ../../users/nivis/home.nix;


    };
    backupFileExtension = null;

  };


  fileSystems."/mnt/games" = {
  device = "/dev/disk/by-uuid/12ef98a6-ad00-4a03-b80b-9b526717e67a";
  fsType = "ext4";
  options = [
    "rw"
    "nofail"
  ];
};


  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true; # optional


  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.space-mono
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;




  programs.ssh.startAgent = true;

  # Install virt-manager and SPICE tools
  environment.systemPackages = with pkgs; [

    protonup-ng
  ];

  environment.sessionVariables = {
    STEAM_EXXTRA_COMPAT_TOOLS_PATHS =
      "/home/user/.steam/root/compatibilitytools.d";
  };

  # Required kernel modules
   # or "kvm-amd"


  # Enable polkit for GUI auth
  security.polkit.enable = true;



  #hardware.nvidia.prime = {
  #  sync.enable = true;
  #
  #  nvidiaBusId = "PCI:1:0:0";
  #};


  services.xserver.videoDrivers = ["nvidia"];



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.11";

}
