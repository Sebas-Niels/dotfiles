{ self, inputs, ... }: {

  flake.nixosModules.lutris = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      lutris
      winetricks
    ];
  };
}