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

  ## Workaround: nixpkgs bug — libvirt generates virt-secret-init-encryption
  ## with /usr/bin/sh which does not exist on NixOS
systemd.services.virt-secret-init-encryption = {
  serviceConfig = {
    ExecStart = [
      ""  # clears the original ExecStart
      (let
        script = pkgs.writeShellScript "virt-secret-init-encryption" ''
          umask 0077
          dd if=/dev/random status=none bs=32 count=1 \
            | ${pkgs.systemd}/bin/systemd-creds encrypt \
                --name=secrets-encryption-key \
                - /var/lib/libvirt/secrets/secrets-encryption-key
        '';
      in "${script}")
    ];
  };
};
}