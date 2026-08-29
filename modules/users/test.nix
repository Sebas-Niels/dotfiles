{ ... }:
{
  flake.nixosModules.test = { pkgs, lib, ... }: {
    options.profiles.test = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Info about the test account.";
    };

    config = {
      users.users."test" = {
        isNormalUser = true;
        description = "test";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        initialPassword = "changeme";
        packages = with pkgs; [
          kdePackages.kate
        ];
      };

      profiles.test = {
        name = "test";
        git = {
          userName = "test";
          userEmail = "test@example.com";
        };
        editor = {
          theme = "gruvbox";
          fontSize = 13;
        };
      };
    };
  };
}
