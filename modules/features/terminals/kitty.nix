{ self, inputs, ... }:
{
  flake.nixosModules.kitty =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaKitty
      ];
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      themes = {
        gruvbox-dark = "gruvbox-dark";
        dainty-dark = "daintyDark";
        duckbones = "duckbones";
        vimbones = "vimbones";
        dracula = "Dracula";
        eldritch = "Eldritch";
        farin = "Farin";
        galaxy = "Galaxy";
      };
    in
    {
      packages.lambdaKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;

        font = {
          name = "JetBrainsMono Nerd Font";
          size = 14.0;
        };

        themeFile = themes.duckbones;

        settings = {
          adjust_line_height = "120%";
          background_opacity = "0.95";
          background_blur = "64";
          shell = lib.getExe self'.packages.lambdaZsh;
        };
      };
    };
}
