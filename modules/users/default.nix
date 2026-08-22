{ config, ... }:
{
  flake.nixosModules.users = {
    imports = with config.flake.nixosModules; [
      nivis
      test
    ];
  };
}
