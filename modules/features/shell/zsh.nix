{ self, inputs, ... }:
{
  flake.nixosModules.zsh =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) lambdaZsh;
    in
    {
      environment.systemPackages = [ lambdaZsh ];
      environment.shells = [ lambdaZsh ];
      environment.pathsToLink = [ "/share/zsh" ];

      users.users.nivis.shell = lambdaZsh;
    };

  perSystem =
    { pkgs, lib, self', ... }:
    {
      packages.lambdaZsh = inputs.wrapper-modules.wrappers.zsh.wrap {
        inherit pkgs;

        hmSessionVariables = null;

        zshAliases = {
          ll = "ls -l";
          gs = "git status";
        };

        runtimePkgs = with pkgs; [ yazi git ];

        env.STARSHIP_CONFIG =
          "${self'.packages.lambdaStarship.configuration.constructFiles."starship.toml"}";

        zshrc.content = ''
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

          eval "$(${lib.getExe self'.packages.lambdaStarship} init zsh)"

          nixrb() {
              sudo nixos-rebuild switch --flake .#$(hostname)
          }

          gitac() {
              git add -A
              git commit -m "$*"
          }
          gitacp() {
              git add -A
              git commit -m "$*"
              git push
          }
          function fexp() {
            local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
            yazi "$@" --cwd-file="$tmp"
            if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              cd -- "$cwd"
            fi
            rm -f -- "$tmp"
          }
        '';
      };
    };
}