{ config, lib, ... }:

{

  wayland.windowManager.hyprland.settings.windowrulev2 = [
  #  "workspace 1, class:^(code|kitty|neovide)$"
  #  "workspace 2, class:^(firefox|spotify|discord)$"
  #  "workspace 3, class:^(steam|lutris)$"
     "stayfocused, title:^()$,class:^(steam)$"
     "minsize 1 1, title:^()$,class:^(steam)$"
  ];

    wayland.windowManager.hyprland.settings.workspace = [
        "special:temp, on-created-empty:spotify"
    ];





}
