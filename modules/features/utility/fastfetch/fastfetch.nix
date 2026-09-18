{ self, inputs, ... }:
{
  flake.nixosModules.fastfetch =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaFastfetch
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.lambdaFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;
        settings = builtins.fromJSON (builtins.readFile ./config/fastfetch/config.jsonc);
      };
    };
}