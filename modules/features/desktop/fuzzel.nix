{ self, ... }: {
  flake.nixosModules.fuzzel = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFuzzel
    ];
  };

  perSystem = { pkgs, lib, self', ... }:
    let
      fuzzelConfig = (pkgs.formats.ini { }).generate "fuzzel.ini" {
        main = {
          font = "monospace:size=18";
          terminal = "${lib.getExe self'.packages.apertureKitty} -e";
          prompt = ''"> "'';
          layer = "overlay";
          width = 40;
          lines = 12;
          horizontal-pad = 24;
          vertical-pad = 18;
          inner-pad = 12;
        };

        # Colors are RRGGBBAA, no leading #
        colors = {
          background = "1e1e2eee";
          text = "cdd6f4ff";
          match = "89b4faff";
          selection = "313244ff";
          selection-text = "cdd6f4ff";
          selection-match = "89b4faff";
          border = "89b4faff";
        };

        border = {
          width = 3;
          radius = 12;
        };
      };
    in
    {
      packages.apertureFuzzel = pkgs.symlinkJoin {
        name = "aperture-fuzzel";
        paths = [ pkgs.fuzzel ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/fuzzel \
            --add-flags "--config ${fuzzelConfig}"
        '';
        meta.mainProgram = "fuzzel";
      };
    };
}