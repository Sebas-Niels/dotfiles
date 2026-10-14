{ self, ... }: {
  flake.nixosModules.mako = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMako
    ];
  };

  perSystem = { pkgs, ... }:
    let
      makoConfig = pkgs.writeText "mako-config" ''
        font=monospace 11
        anchor=top-right
        layer=overlay
        width=360
        margin=10
        padding=12
        border-size=2
        border-radius=8
        default-timeout=5000

        background-color=#1e1e2eee
        text-color=#cdd6f4
        border-color=#89b4fa
        progress-color=over #313244

        [urgency=low]
        border-color=#313244

        [urgency=high]
        border-color=#fab387
        default-timeout=0
      '';
    in
    {
      packages.apertureMako = pkgs.symlinkJoin {
        name = "aperture-mako";
        paths = [ pkgs.mako ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/mako \
            --add-flags "--config ${makoConfig}"
        '';
        meta.mainProgram = "mako";
      };
    };
}