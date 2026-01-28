{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name  = "Sebastian NIelsen";
      email = "sebas.nn@tuta.com";
    };
  };
}
