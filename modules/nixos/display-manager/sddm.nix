{ inputs, pkgs, ... }:
{

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    #theme = "sddm-astronaut-theme";
  };

environment.variables = {
	SDDM_WAYLAND_NO_MODESET = "1";
};
environment.sessionVariables.XDG_DATA_DIRS = [
	"${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/share"
];
environment.etc."wayland-sessions/hyprland.desktop".text = ''
	[Desktop Entry]
	Name=Hyprland
	Comment=An intelligent dynamic tiling Wayland compositor
	Exec=Hyprland
	Type=Application
'';
  services.displayManager.defaultSession = "hyprland";

  services.xserver = {
    enable = true;

    xkb = {
      layout = "dk";
      variant = "";
    };

  };

}

