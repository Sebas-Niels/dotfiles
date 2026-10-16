{ self, ... }: {
  flake.nixosModules.mako = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMako
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
      makoConfig = t: ''
        font=monospace 11
        anchor=top-right
        layer=overlay
        width=360
        margin=10
        padding=12
        border-size=2
        border-radius=8
        default-timeout=5000

        background-color=${t.c.bg}ee
        text-color=${t.c.text}
        border-color=${t.c.accent}
        progress-color=over ${t.c.surface}

        [urgency=low]
        border-color=${t.c.surface}

        [urgency=high]
        border-color=${t.c.yellow}
        default-timeout=0
      '';

      mako = pkgs.writeShellScript "mako" ''
        ${lib.getExe self'.packages.apertureTheme} init
        exec ${lib.getExe pkgs.mako} --config "$HOME/.local/state/aperture-theme/current/mako" "$@"
      '';
    in
    {
      apertureTheme.targets."mako" = makoConfig;

      packages.apertureMako = pkgs.symlinkJoin {
        name = "aperture-mako";
        paths = [ pkgs.mako ];
        postBuild = ''
          rm $out/bin/mako
          ln -s ${mako} $out/bin/mako
        '';
        meta.mainProgram = "mako";
      };
    };
}
