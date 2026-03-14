{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Uncomment and adjust if using PRIME (e.g. hybrid laptop GPU)
  #hardware.nvidia.prime = {
  #  sync.enable = true;
  #  nvidiaBusId = "PCI:1:0:0";
  #};
	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement = {
			enable = true;
			finegrained = false;
		};
		open = false;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.stable;
		forceFullCompositionPipeline = true;


	};

  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
