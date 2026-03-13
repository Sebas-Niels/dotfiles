{ ... }:
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
}
