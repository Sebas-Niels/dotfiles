{ self, inputs, ... }: {

  flake.nixosModules.lutris = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      (lutris.override {
        extraPkgs = pkgs: with pkgs; [
          wineWowPackages.stable
          winetricks
        ];
      })
      winetricks
    ];
  };
}