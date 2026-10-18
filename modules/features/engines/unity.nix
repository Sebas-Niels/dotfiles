{ self, inputs, ... }:
{
  flake.nixosModules.unity =
    { pkgs, ... }:
    let
      uiScale = 2; # GDK only accepts integers
      textScale = 0.65; # multiplies uiScale for text, so 2 * 0.65 = 1.3x text

      # Unity's shader compiler links against a Debian-style libtinfo.so.6 with
      # versioned symbols. nixpkgs' libtinfo is only a symlink to libncursesw, so
      # ldconfig never caches it under that name inside the FHS env.
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
            # Tools the editor shells out to
            extraPkgs =
              pkgs: with pkgs; [
                pciutils # lspci, used by the bug reporter
              ];

            # Libraries the editor needs that the hub's FHS env lacks
            extraLibs =
              pkgs: with pkgs; [
                libtinfo # needed by UnityShaderCompiler and libdxcompiler
                ocl-icd # libOpenCL.so.1, needed by the GPU lightmapper (RadeonRays)
                libdecor # needed by Linux player builds on Wayland
              ];
          }).overrideAttrs
            (old: {
              # The Linux editor has no UI scaling setting and only follows GDK's
              # integer scale. GDK_DPI_SCALE shrinks text back for a ~1.3x feel.
              # The editor is launched by the hub, so it inherits these.
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
