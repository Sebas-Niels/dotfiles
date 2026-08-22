{ self, inputs, ... }:
{
  flake.nixosModules.starship =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) lambdaStarship;
    in
    {
      environment.systemPackages = [ lambdaStarship ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.lambdaStarship = inputs.wrapper-modules.wrappers.starship.wrap {
        inherit pkgs;

        settings = {
          add_newline = false;
          jobs = {
            disabled = false;
            symbol_threshold = 1;
          };
          username = {
            show_always = true;
            format = "[$user](bright-yellow)";
          };
          hostname = {
            ssh_only = false;
            format = "[@](bright-green)[$hostname](bright-blue) ";
          };
          format = "┌[\\[](bright-red)$username$hostname$directory[\\] ](bright-red)$git_branch$git_status\n└─►$character";
          directory = {
            truncation_length = 0;
            truncate_to_repo = false;
            home_symbol = "~";
            truncation_symbol = "/";
            format = "[$path](bright-purple)";
          };
          git_branch.format = "on [$symbol$branch](blue) ";
          character = {
            success_symbol = "\\$";
            error_symbol = "[\\$](red)";
            vimcmd_symbol = "[V](white)";
          };
        };
      };
    };
}