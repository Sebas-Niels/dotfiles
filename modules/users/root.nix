{ self, ... }:
{
  flake.nixosModules.root =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) lambdaZsh;
    in
    {
      users.users.root.shell = lambdaZsh;
      environment.shells = [ lambdaZsh ];
    };
}
