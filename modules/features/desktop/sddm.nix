{ ... }: {
  flake.nixosModules.sddm = { pkgs, ... }: let
    theme = pkgs.where-is-my-sddm-theme.override {
      themeConfig.General = {
        passwordCharacter = "*";
        passwordFontSize = 96;
        backgroundFill = "#000000";
        basicTextColor = "#ffffff";
      };
    };
  in {
    services.xserver.enable = true;

    services.displayManager.sddm = {
      enable = true;
      theme = "${theme}/share/sddm/themes/where_is_my_sddm_theme";
      extraPackages = [ theme ];
    };
  };
}