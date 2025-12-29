  # Define a user account. Don't forget to set a password with ‘passwd’.
{ pkgs, ... }:
{
  users.users.nixos = {
    isNormalUser = true;
    description = "nixos";
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };
}
