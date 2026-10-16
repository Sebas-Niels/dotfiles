{ self, inputs, ... }: {

  flake.nixosModules.apertureConfiguration = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      grubEfi
      apertureHardware
      #niri
      #noctalia
      git
      users
      danishLocale
      pipewireAudio
      sddm
      printing
      networkManager
      sshAgent
      graphics
      steam
      kitty
      ghostty
      starship
      zsh
      defaultApps
      fastfetch
      mpd
      rmpc
      foreignApps
      lazygit
      helpwire
      godot
      lutris
      mangowm
    ];

    environment.systemPackages = with pkgs; [
      librewolf
      git
      kitty
      kdePackages.dolphin
      kdePackages.kio-extras
      kdePackages.qtwayland
      kdePackages.breeze
      papirus-icon-theme
      claude-code
      unzip
      ddcutil # This is for allowing noctalia to change screen brightness
    ];

    hardware.i2c.enable = true;
    boot.kernelModules = [ "i2c-dev" ];

    services.flatpak.enable = true;

    environment.shellAliases = {
      nixrb = "sudo nixos-rebuild switch --flake .#$(hostname)";
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;

    networking.hostName = "aperture";
    system.stateVersion = "26.05";
  };
}
