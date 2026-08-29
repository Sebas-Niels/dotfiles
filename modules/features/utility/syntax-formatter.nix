{ ... }:
{
  perSystem = { pkgs, ... }: {
    syntax-formatter = pkgs.nixfmt-tree;
  };
}