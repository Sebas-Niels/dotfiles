# This used to be the configuration.nix file, but is renamed to default.nix for flakes convention and convenience.
# Nix automatically imports the default.nix in a directory.
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/nixos/utility/filesystems.nix
    inputs.home-manager.nixosModules.default

    # Bootloader
    ../../modules/nixos/boot/grub.nix
    # Time & Locale
    ../../modules/nixos/utility/locale.nix
    # X11 & Desktop environment
    #../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/hyprland.nix
    # Printing
    ../../modules/nixos/printing.nix
    # Audio
    ../../modules/nixos/audio/pipewire.nix
    ../../modules/nixos/audio/music.nix
    # Role Programs
    ../../modules/nixos/roles/workstation.nix
    ../../modules/nixos/roles/gaming.nix
    # Nix Settings
    ../../modules/nixos/base.nix
    # Virtualisation
    ../../modules/nixos/virtualisation/kvm_qemu.nix
    # Hardware
    ../../modules/nixos/graphics/nvidia.nix
    # Fonts
    ../../modules/nixos/utility/fonts.nix
    # Security / Secrets
    ../../modules/nixos/security/keyring.nix
    ../../modules/nixos/display-manager/greetd.nix
    # User definition
    ../../users/nivis/user.nix
    ../../modules/nixos/shell/zsh.nix
  ];

  # /etc/nixos/configuration.nix
programs.appimage = {
  enable = true;
  binfmt = true;  # lets you run AppImages directly like any executable
};

  services.flatpak.enable = true;

  networking.hostName = "lambda";
  networking.networkmanager.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "nivis" = import ../../users/nivis/home.nix;
    };
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment.shellAliases = {
    nixrb = "sudo nixos-rebuild switch --flake .#$(hostname)";
  };

  nix.settings.download-buffer-size = 524288000; # 500MB

  system.stateVersion = "25.11";
}
