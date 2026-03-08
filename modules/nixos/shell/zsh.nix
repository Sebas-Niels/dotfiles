{ config, inputs, pkgs, ... }:
{
    programs.zsh = {
        enable = true;

        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
            ll = "ls -l";
            gs = "git status";
        };
    };

    
}
