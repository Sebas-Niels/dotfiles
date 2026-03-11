{ ... }:
{

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    #theme = "sddm-astronaut-theme";
  };

  services.xserver = {
    enable = true;

    xkb = {
      layout = "dk";
      variant = "";
    };
  };

}

