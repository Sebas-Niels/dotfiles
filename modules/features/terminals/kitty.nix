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
        # Dark themes:
        gruvbox-dark = "gruvbox-dark";
        dainty-dark = "daintyDark";
        duckbones = "duckbones";
        vimbones = "vimbones";
        dracula = "Dracula";
        eldritch = "Eldritch";
        farin = "Farin";
        galaxy = "Galaxy";
        base2tone-field-dark = "base2tone-field-dark";
        blueloco-dark = "BlulocoDark";
        challenger-deep = "ChallengerDeep";
        cherry = "cherry";
        cherry-midnight = "cherry-midnight";
        cobalt-neon = "Cobalt_Neon";
        cyberpunk = "cyberpunk";
        cyberpunk-neon = "Cyberpunk-Neon";
        kaolin-aurora = "Kaolin_Aurora";
        kaolin-galaxy = "Kaolin_Galaxy";
        midsummer-night = "midsummer-night";
        moonfly = "moonfly";
        moonlight = "moonlight";
        night-owl = "night_owl";
        rose-pine = "rose-pine";
        sea-shells = "SeaShells";
        spacedust = "Spacedust";
        toy-chest = "ToyChest";

        # Light themes:
        solarized-light = "Solarized_Light";
        solarized-osaka-light = "solarized_osaka_light";
        gruvbox-light = "GruvboxMaterialLightHard";
      };
    in
    {
      packages.lambdaKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;

        font = {
          name = "JetBrainsMono Nerd Font";
          size = 14.0;
        };
        # Dark theme:
        #themeFile = themes.moonlight;
        #Light theme:
        themeFile = themes.gruvbox-light;

        settings = {
          adjust_line_height = "120%";
          background_opacity = "0.60";
          background_blur = "64";
          shell = lib.getExe self'.packages.lambdaZsh;
        };
      };
    };
}
