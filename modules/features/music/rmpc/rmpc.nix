{ self, inputs, ... }:
{
  flake.nixosModules.rmpc =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureRmpc
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.apertureRmpc = inputs.wrapper-modules.lib.evalPackage [
        { inherit pkgs; }
        (
          {
            config,
            wlib,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [ wlib.modules.default ];
            package = lib.mkDefault pkgs.rmpc;
            flags."--config" = config.constructFiles.rmpcConfig.path;
            constructFiles.rmpcConfig = {
              relPath = "rmpc/config.ron";
              content = builtins.readFile ./config.ron;
            };
          }
        )
      ];
    };
}
