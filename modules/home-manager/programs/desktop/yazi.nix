{ pkgs, ... }:

{
  programs.yazi.enable = true;

  home.packages = with pkgs; [
    xdg-utils
  ];

  xdg.configFile."yazi/yazi.toml".text = ''
    [opener]
    open = [
      { run = 'xdg-open "$@"', desc = "Open (default app)", for = "unix" }
    ]
  '';

xdg.configFile."yazi/keymap.toml".text = ''
  [manager]
  prepend_keymap = [
    { on = [ "o" ], run = "open", desc = "Open (default app)" },
  ]
'';

}
