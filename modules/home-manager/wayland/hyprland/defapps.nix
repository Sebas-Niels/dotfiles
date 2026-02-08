{ config, pkgs, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    qimgv
  ];

  xdg.desktopEntries.qimgv = {
    name = "qimgv";
    exec = "${pkgs.qimgv}/bin/qimgv %U";
    terminal = false;
    categories = [ "Graphics" "Viewer" ];
    mimeType = [
      "image/png"
      "image/jpeg"
      "image/webp"
      "image/gif"
      "image/bmp"
      "image/tiff"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = [ "qimgv.desktop" ];
      "image/jpeg" = [ "qimgv.desktop" ];
      "image/webp" = [ "qimgv.desktop" ];
      "image/gif" = [ "qimgv.desktop" ];
      "image/bmp" = [ "qimgv.desktop" ];
      "image/tiff" = [ "qimgv.desktop" ];

      "text/plain" = [ "org.kde.kate.desktop" ];

      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };
}
