{ ... }: {
  flake.nixosModules.networkManager = { ... }: {
    networking.networkmanager.enable = true;
  };
}
