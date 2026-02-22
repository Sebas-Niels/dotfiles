  # Define a user account. Don't forget to set a password with ‘passwd’.
{ pkgs, ... }:

{
  users.users."vm-user" = {
    isNormalUser = true;
    description = "vm-user";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "kvm" "storage" "disk" ];
    #shell = pkgs.zsh;
  };
}
