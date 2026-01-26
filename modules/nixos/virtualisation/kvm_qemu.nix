{ config, pkgs, lib, ... }:

{
  ## KVM / QEMU / libvirt
  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };

    allowedBridges = [ "virbr0" ];
  };

  virtualisation.spiceUSBRedirection.enable = true;


  ## virt-manager
  programs.virt-manager.enable = true;

  ## Required kernel modules (CPU-agnostic)
  boot.kernelModules =
    lib.optionals config.hardware.cpu.intel.updateMicrocode [ "kvm-intel" ]
    ++ lib.optionals config.hardware.cpu.amd.updateMicrocode [ "kvm-amd" ];

  ## Firewall for libvirt NAT
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  ## Polkit for GUI auth
  security.polkit.enable = true;

  ## VM tooling
  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
  ];
}
