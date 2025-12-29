# Includes modules or common programs needed for this role, not defined by the users configuration
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    discord
    git
    #spotify
  ];


    # Install firefox.
  programs.firefox.enable = true;
