{ ... }:
{
  flake.nixosModules.graphics = {
    services.xserver.videoDrivers = [ "nvidia" ];
    # nixpkgs only loads these when services.xserver.enable is set.
    boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      open = true;
    };
  };
}
