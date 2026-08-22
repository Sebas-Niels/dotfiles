{ ... }: {
    flake.nixosModules.sddm = { ... }: {
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
    };
}