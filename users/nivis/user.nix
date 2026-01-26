  # Define a user account. Don't forget to set a password with ‘passwd’.
{ pkgs, ... }:

{
  users.users.nivis = {
    isNormalUser = true;
    description = "nivis";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "kvm" "storage" "disk" ];
    #shell = pkgs.zsh;
  };
}
