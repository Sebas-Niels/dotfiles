{ ... }:
{
  flake.nixosModules.nivis = { pkgs, ... }: {
    users.users."nivis" = {
      isNormalUser = true;
      description = "nivis";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      initialPassword = "changeme";
      packages = with pkgs; [
        kdePackages.kate
        vesktop
        spotify
        obsidian
        tutanota-desktop
        anydesk
        bitwarden-desktop
        vscode
        qalculate-qt
        lm_sensors
        wootility
        imhex
        _1password-gui
        wireshark
        p7zip
        signal-desktop
        yazi
        spotiflac
        lazygit
      ];
    };

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.space-mono
    ];
  };

  flake.profiles.nivis = {
    name = "nivis";
    git = {
      userName = "Sebastian Nielsen";
      userEmail = "sebas.nn@tuta.com";
    };
    # Currently does nothing
    # Eventually configure kitty to take info from this section below
    editor = {
      theme = "gruvbox";
      fontSize = 13;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14.0;
    };
  };
}
