{ self, inputs, ... }:
{
  flake.nixosModules.zsh =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) apertureZsh;
    in
    {
      environment.systemPackages = [ apertureZsh ];
      environment.shells = [ apertureZsh ];
      environment.pathsToLink = [ "/share/zsh" ];

      users.users.nivis.shell = apertureZsh;
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.apertureZsh = inputs.wrapper-modules.wrappers.zsh.wrap {
        inherit pkgs;

        hmSessionVariables = null;

        zshAliases = {
          ll = "ls -l";
          gs = "git status";
        };

        runtimePkgs = with pkgs; [
          yazi
          git
        ];

        env.STARSHIP_CONFIG = "${self'.packages.apertureStarship.configuration.constructFiles."starship.toml"
        }";

        zshrc.content = ''
          autoload -Uz compinit && compinit

          eval "$(${lib.getExe self'.packages.apertureStarship} init zsh)"

          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

          nixrb() {
              sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)
          }

          gitac() {
              git add -A
              git commit -m "$*"
          }
          gitacp() {
              git add -A && git commit -m "$*" && git push
          }

          ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

          # Must stay last — hooks run in registration order.
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        '';
      };
    };
}
