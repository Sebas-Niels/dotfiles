{ self, inputs, ... }:
{
  flake.nixosModules.fastfetch =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFastfetch
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.apertureFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;
        settings = builtins.fromJSON (builtins.readFile ./config.json);
      };
    };
}
