{ pkgs, ... }:
{
  security.polkit.enable = true;

  services.gnome = {
    gnome-keyring.enable = true;
    gcr-ssh-agent.enable = false;
  };

  environment.systemPackages = with pkgs; [
    libsecret
  ];

  programs.ssh.startAgent = true;
}
