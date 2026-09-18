{ self, ... }:
{
  flake.nixosModules.root =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) apertureZsh;
    in
    {
      users.users.root.shell = apertureZsh;
      environment.shells = [ apertureZsh ];
    };
}
