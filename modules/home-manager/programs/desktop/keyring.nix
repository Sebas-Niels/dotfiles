{ pkgs, ... }:

{
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.swaylock.enableGnomeKeyring = true; # optional
  security.pam.services.greetd.enableGnomeKeyring = true;


    environment.systemPackages = with pkgs; [
        gnome-keyring
        libsecret
  ];
}
