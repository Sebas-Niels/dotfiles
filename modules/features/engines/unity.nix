{ self, inputs, ... }:
{
  flake.nixosModules.unity =
    { pkgs, ... }:
    let
      uiScale = 2;
      textScale = 0.65;

      libtinfo =
        let
          ncurses = pkgs.ncurses.overrideAttrs (old: {
            configureFlags = old.configureFlags ++ [
              "--with-termlib"
              "--with-versioned-syms"
            ];
          });
        in
        pkgs.runCommand "libtinfo-6" { nativeBuildInputs = [ pkgs.patchelf ]; } ''
          mkdir -p $out/lib
          cp ${ncurses.out}/lib/libtinfow.so.6.* $out/lib/libtinfo.so.6
          chmod +w $out/lib/libtinfo.so.6
          patchelf --set-soname libtinfo.so.6 $out/lib/libtinfo.so.6
        '';
    in
    {
      environment.systemPackages = [
        (
          (pkgs.unityhub.override {
            extraPkgs =
              pkgs: with pkgs; [
                pciutils
              ];

            extraLibs =
              pkgs: with pkgs; [
                libtinfo
                ocl-icd
                libdecor
              ];
          }).overrideAttrs
            (old: {
              postFixup = (old.postFixup or "") + ''
                wrapProgram $out/opt/unityhub/unityhub \
                  --set GDK_SCALE ${toString uiScale} \
                  --set GDK_DPI_SCALE ${toString textScale}
              '';
            })
        )
      ];
    };
}
