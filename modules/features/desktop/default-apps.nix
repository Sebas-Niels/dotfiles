{ ... }:
{
  flake.nixosModules.defaultApps =
    { lib, pkgs, ... }:
    let
      browser = "librewolf.desktop";

      browserTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/pdf"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ];
    in
    {
      xdg.mime.defaultApplications = lib.genAttrs browserTypes (_: browser);

      system.userActivationScripts.defaultApps = ''
        ${pkgs.xdg-utils}/bin/xdg-mime default ${browser} ${lib.concatStringsSep " " browserTypes}
      '';
    };
}
