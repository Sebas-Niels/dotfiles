
{ lib, config, pkgs, ... }:

{
    users.users."mainuser" = {
        isNormalUser = true;
        initialPassword = "123";
        description = "main user";
        shell = pkgs.zsh;
    };
}
