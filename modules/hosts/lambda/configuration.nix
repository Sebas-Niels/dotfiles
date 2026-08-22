{self, inputs, ... }: {

  flake.nixosModules.lambdaConfiguration = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      grubEfi
      lambdaHardware
      niri
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
    ];

    environment.systemPackages = with pkgs; [
      librewolf
      firefox
      git
      kitty
      kdePackages.dolphin
      kdePackages.breeze
      papirus-icon-theme
      claude-code
    ];

    programs.firefox.enable = true;

    services.flatpak.enable = true;

    environment.shellAliases = {
      nixrb = "sudo nixos-rebuild switch --flake .#$(hostname)";
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    nixpkgs.config.allowUnfree = true;

    networking.hostName = "lambda";
    system.stateVersion = "26.05";
  };
}
