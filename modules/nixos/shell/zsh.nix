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
    jobs = {
      disabled = false;
      symbol_threshold = 1;
    };
    username = {
      show_always = true;
      format = "[$user](blue)";
    };
    hostname = {
      ssh_only = false;
      format = "[@](yellow)[$hostname]($style) ";
    };
    format = "$username$hostname[../](bright-blue)$directory$git_branch$git_status\n$character";
    directory = {
      truncation_length = 0;
    };
  };

  presets = [
  ];
};

    
}
