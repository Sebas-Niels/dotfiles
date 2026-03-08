{ config, inputs, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        moreutils
    ];


    programs.zsh = {
        enable = true;

        

        syntaxHighlighting.enable = true;

        shellAliases = {
            ll = "ls -l";
            gs = "git status";
        };

        interactiveShellInit = ''
            gitacp() {
                git add -A
                git commit -m "$*"
                git push
            }
        '';
    };

    programs.starship = {
        enable = true;

        settings = {
            add_newline = false;

            character = {
                #success_symbol = "[➜](green)";
                #error_symbol = "[➜](red)";
            };

            #palette = "test-palette";

            palettes.test-palette = {
                red = "#823A2C";
            };

            time.disabled = true;

        };
    };

    
}
