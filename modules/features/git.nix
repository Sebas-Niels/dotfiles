{ self, ... }:
{
  flake.nixosModules.git =
    { ... }:
    {
      programs.git = {
        enable = true;
        config = {
          user = {
            name = self.profiles.nivis.git.userName;
            email = self.profiles.nivis.git.userEmail;
          };
          init.defaultBranch = "main";
        };
      };
    };
}
