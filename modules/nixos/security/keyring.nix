{ pkgs, ... }:
{
  security.polkit.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;  # explicitly disable
  environment.systemPackages = with pkgs; [ libsecret ];
  programs.ssh.startAgent = true;
}