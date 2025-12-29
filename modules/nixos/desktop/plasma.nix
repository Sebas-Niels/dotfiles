{ ... }:
{
  # Enable X11
  services.xserver = {
    enable = true;

    xkb = {
      layout = "dk";
      variant = "";
    };
  };

  # Display manager
  services.displayManager.sddm.enable = true;

  # Desktop environment
  services.desktopManager.plasma6.enable = true;
}

