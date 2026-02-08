{ config, pkgs, ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # PDFs
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];

      # Images
      "image/png" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];

      # Text files
      "text/plain" = [ "kate.desktop" ]; # or "code.desktop", "org.gnome.gedit.desktop", etc.

      # Directories (file manager)
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

      # HTML
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];

      # Mailto links
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
    };
  };
}
