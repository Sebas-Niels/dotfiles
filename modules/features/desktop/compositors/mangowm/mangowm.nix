{ self, inputs, ... }: {
  flake.nixosModules.mangowm = { pkgs, ... }: {
    imports = [
      inputs.mango.nixosModules.mango
      self.nixosModules.fuzzel
      self.nixosModules.swaybg
      self.nixosModules.mako
      self.nixosModules.waybar
    ];

    programs.mango = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
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

        "exec-once" = [
          "${lib.getExe self'.packages.apertureSwaybg}"
          "${lib.getExe self'.packages.apertureWaybar}"
          "${lib.getExe self'.packages.apertureMako}"
        ];

        bind = [
          "SUPER,Return,spawn,${lib.getExe self'.packages.apertureKitty}"
          "SUPER,d,spawn,${lib.getExe self'.packages.apertureFuzzel}"
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