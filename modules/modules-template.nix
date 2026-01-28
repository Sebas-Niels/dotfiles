{ config, pkgs, ... }:

{
  imports =
    [ # import other modules here
    ];

  options = {
    # ...
  };

  config = {
    # ...
  };
}



{ config, inputs, pkgs, ... }:
{
    imports = [
    ./browsers.nix
    ];
}
