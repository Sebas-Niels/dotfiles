{ ... }: {
  flake.nixosModules.foreignApps = { ... }: {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    services.flatpak.enable = true;
    xdg.portal.enable = true;
  };
}