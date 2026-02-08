{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    xdg-utils
  ];

  home-manager.users.nivis = { ... }: {
    programs.yazi.enable = true;

    xdg.configFile."yazi/yazi.toml".text = ''
      [opener]
      open = [
        { run = 'xdg-open "$@"', desc = "Open (default app)", for = "unix" }
      ]
    '';

    xdg.configFile."yazi/keymap.toml".text = ''
      [manager]
      keymap = [
        { on = [ "<Enter>" ], run = "open", desc = "Open (default app)" },
      ]
    '';
  };
}
