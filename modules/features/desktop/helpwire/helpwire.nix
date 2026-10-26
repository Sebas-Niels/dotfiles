{ self, inputs, ... }: {

  flake.nixosModules.helpwire =
    { pkgs, ... }:
    let
      helpwire = self.packages.${pkgs.stdenv.hostPlatform.system}.helpwire-operator;
    in
    {
      environment.systemPackages = [ helpwire ];

      environment.etc."HelpWire/Operator/main.conf".source =
        "${helpwire}/etc/HelpWire/Operator/main.conf";

      systemd.tmpfiles.rules = [
        "d /var/lib/HelpWire 1777 root root -"
        "d /var/log/HelpWire 1777 root root -"
      ];
    };

  perSystem = { pkgs, lib, ... }: {
    packages = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      helpwire-operator = pkgs.callPackage (
        {
          lib,
          stdenv,
          rpm,
          cpio,
          autoPatchelfHook,
          makeWrapper,
          libGL,
          fontconfig,
          freetype,
          libpng,
          udev,
          wayland,
          libxkbcommon,
          zlib,
          util-linux,
          dbus,
          xdg-utils,
          libx11,
          libxau,
          libxdmcp,
          libxext,
          libxfixes,
          libxinerama,
          libxrandr,
          libxtst,
          libxcb-wm,
          libxcb-image,
          libxcb-keysyms,
          libxcb-render-util,
        }:

        stdenv.mkDerivation {
          pname = "helpwire-operator";
          version = "2.2.30.11";
          src = ./helpwire-operator.rpm;

          nativeBuildInputs = [
            rpm
            cpio
            autoPatchelfHook
            makeWrapper
          ];

          buildInputs = [
            stdenv.cc.cc.lib
            libGL
            fontconfig
            freetype
            libpng
            udev
            wayland
            libxkbcommon
            zlib
            util-linux.lib
            libx11
            libxau
            libxdmcp
            libxext
            libxfixes
            libxinerama
            libxrandr
            libxtst
            libxcb-wm
            libxcb-image
            libxcb-keysyms
            libxcb-render-util
          ];

          unpackPhase = ''
            rpm2cpio $src | cpio -idm
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/opt $out/bin $out/etc $out/share/applications
            cp -r opt/HelpWire $out/opt/
            cp -r etc/HelpWire $out/etc/

            addAutoPatchelfSearchPath $out/opt/HelpWire/Operator/lib

            makeWrapper $out/opt/HelpWire/Operator/bin/helpwire-operator $out/bin/helpwire-operator \
              --set QT_QPA_PLATFORM xcb \
              --chdir "$out/opt/HelpWire/Operator" \
              --prefix LD_LIBRARY_PATH : ${
                lib.makeLibraryPath [
                  dbus
                  libGL
                ]
              } \
              --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

            for s in 16 24 32 48 64 96 128 256; do
              install -Dm644 opt/HelpWire/Operator/desktop/helpwire-operator_$s.png \
                $out/share/icons/hicolor/''${s}x''${s}/apps/helpwire-operator.png
            done

            cat > $out/share/applications/helpwire-operator.desktop <<EOF
            [Desktop Entry]
            Type=Application
            Name=HelpWire Operator
            Comment=Remote control solution
            Exec=$out/bin/helpwire-operator %u
            Icon=helpwire-operator
            Terminal=false
            Categories=Network;RemoteAccess;
            MimeType=x-scheme-handler/helpwire;
            EOF

            runHook postInstall
          '';

          meta = {
            description = "HelpWire Operator remote support client";
            mainProgram = "helpwire-operator";
            platforms = [ "x86_64-linux" ];
          };
        }
      ) { };
    };
  };
}
