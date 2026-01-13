  # Define a user account. Don't forget to set a password with ‘passwd’.
{ pkgs, ... }:
{
  users.users.nixtest = {
    isNormalUser = true;
    description = "nixtest";
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
      kdePackages.kate
      _1password-gui
    ];
  };
}
