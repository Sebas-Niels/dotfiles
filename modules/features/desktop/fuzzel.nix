{ self, ... }: {
  flake.nixosModules.fuzzel = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFuzzel
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
      fuzzelConfig =
        t:
        lib.generators.toINI { } {
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

          colors = {
            background = "${t.bare t.c.bg}ee";
            text = "${t.bare t.c.text}ff";
            match = "${t.bare t.c.accent}ff";
            selection = "${t.bare t.c.surface}ff";
            selection-text = "${t.bare t.c.text}ff";
            selection-match = "${t.bare t.c.accent}ff";
            border = "${t.bare t.c.accent}ff";
          };

          border = {
            width = 1;
            radius = 0;
          };
        };

      fuzzel = pkgs.writeShellScript "fuzzel" ''
        exec ${lib.getExe pkgs.fuzzel} --config "$HOME/.local/state/aperture-theme/current/fuzzel.ini" "$@"
      '';
    in
    {
      apertureTheme.targets."fuzzel.ini" = fuzzelConfig;

      packages.apertureFuzzel = pkgs.symlinkJoin {
        name = "aperture-fuzzel";
        paths = [ pkgs.fuzzel ];
        postBuild = ''
          rm $out/bin/fuzzel
          ln -s ${fuzzel} $out/bin/fuzzel
        '';
        meta.mainProgram = "fuzzel";
      };
    };
}
