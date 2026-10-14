{ self, inputs, ... }: {
  flake.nixosModules.mangowm = { pkgs, ... }: {
    programs.mango = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango;
    };
  };
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.apertureMango = inputs.wrapper-modules.wrappers.mangowc.wrap {
        inherit pkgs;
        settings = {
          xkb_rules_layout = "us";
          numlockon = 1;
          sloppyfocus = 1;

          gappih = 5;
          gappiv = 5;
          gappoh = 5;
          gappov = 5;

          env = [
            "XCURSOR_THEME,breeze_cursors"
            "XCURSOR_SIZE,24"
          ];

          bind = [
            "SUPER,Return,spawn,${lib.getExe self'.packages.apertureKitty}"
            "SUPER,d,spawn,${lib.getExe self'.packages.apertureNoctalia} ipc call launcher toggle"
            "SUPER,q,killclient"
            "SUPER,r,reload_config"
            "SUPER+SHIFT,e,quit"

            "SUPER,h,focusdir,left"
            "SUPER,l,focusdir,right"
            "SUPER,k,focusdir,up"
            "SUPER,j,focusdir,down"

            "SUPER,f,togglefullscreen"
            "SUPER,space,togglefloating"
          ];
        };
      };
    };
}
