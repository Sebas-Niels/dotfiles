{ inputs, config, pkgs, ... }:
{
  services.greetd = {
  enable = true;
  settings = {
    default_session = {
      #command = "${pkgs.regreet}/bin/regreet";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      user = "greeter";
    };
  };
};
}
