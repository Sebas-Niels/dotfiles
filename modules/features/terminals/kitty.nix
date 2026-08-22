{ self, inputs, ... }:
{
  flake.nixosModules.kitty =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaKitty
      ];
    };

  perSystem = { pkgs, lib, self', ... }: {
      packages.lambdaKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;

        font = {
          name = "JetBrainsMono Nerd Font";
          size = 14.0;
        };

        themeFile = "gruvbox-dark";

        settings = {
          adjust_line_height = "120%";
          background_opacity = "1";
          shell = lib.getExe self'.packages.lambdaZsh;
        };
      };
    };
}