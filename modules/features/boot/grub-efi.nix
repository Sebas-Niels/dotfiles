{ ... }: {
  flake.nixosModules.grubEfi = { pkgs, lib, ... }: {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
