{ pkgs, ... }:
{
  security.polkit.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome = {
    gnome-keyring.enable = true;
    gcr-ssh-agent.enable = true;  # Change this to true — this IS the SSH agent
  };
  environment.systemPackages = with pkgs; [
    libsecret
  ];
  # Remove programs.ssh.startAgent
}