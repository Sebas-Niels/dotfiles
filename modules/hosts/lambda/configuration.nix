{ self, inputs, ... }: {

  flake.nixosModules.lambdaConfiguration = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      grubEfi
      lambdaHardware
      niri
      noctalia
      git
      users
      danishLocale
      pipewireAudio
      sddm
      printing
      networkManager
      graphics
      steam
      kitty
      starship
      zsh
      defaultApps
      fastfetch
      rmpc
      foreignApps
      lazygit
      #theming
      lightTheming
    ];

    environment.systemPackages = with pkgs; [
      librewolf
      git
      kitty
      kdePackages.dolphin
      kdePackages.breeze
      papirus-icon-theme
      claude-code
    ];

    services.flatpak.enable = true;

    environment.shellAliases = {
      nixrb = "sudo nixos-rebuild switch --flake .#$(hostname)";
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;

    networking.hostName = "lambda";
    system.stateVersion = "26.05";
  };
}
