{ config, lib, ... }:

{

  wayland.windowManager.hyprland.settings.windowrulev2 = [
  #  "workspace 1, class:^(code|kitty|neovide)$"
  #  "workspace 2, class:^(firefox|spotify|discord)$"
  #  "workspace 3, class:^(steam|lutris)$"
     "stayfocused, title:^()$,class:^(steam)$"
     "minsize 1 1, title:^()$,class:^(steam)$"
     #"float, class:.*"
     #"center, class:.*"
  ];

    wayland.windowManager.hyprland.settings.workspace = [
        "special:music, on-created-empty:spotify"
        "special:notes, on-created-empty:obsidian"
    ];





}
