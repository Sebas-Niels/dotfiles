{ self, inputs, ... }: {

    flake.nixosModules.lambdaHardware = {config, lib, pkgs, modulesPath, ... }: {
        imports = [
            (modulesPath + "/installer/scan/not-detected.nix")
        ];


        boot.initrd.availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
            device = "/dev/disk/by-uuid/7190b3e6-b97f-4232-a1d9-7db4380e440d";
            fsType = "ext4";
        };

        fileSystems."/boot" = {
            device = "/dev/disk/by-uuid/710C-D4A4";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
        };

        fileSystems."/mnt/games" = {
            device = "/dev/disk/by-uuid/12ef98a6-ad00-4a03-b80b-9b526717e67a";
            fsType = "ext4";
            options = [ "nofail" "x-gvfs-show" ];
        };

        swapDevices = [ ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
