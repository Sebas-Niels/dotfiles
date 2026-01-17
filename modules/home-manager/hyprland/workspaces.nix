{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Workspace switching
      "SUPER, 1, exec, hyprctl dispatch moveworkspacetomonitor 1 current && hyprctl dispatch workspace 1"
      "SUPER, 2, exec, hyprctl dispatch moveworkspacetomonitor 2 current && hyprctl dispatch workspace 2"
      "SUPER, 3, exec, hyprctl dispatch moveworkspacetomonitor 3 current && hyprctl dispatch workspace 3"
      "SUPER, 4, exec, hyprctl dispatch moveworkspacetomonitor 4 current && hyprctl dispatch workspace 4"
      "SUPER ALT, c, togglespecialworkspace, temp"

      # Move windows
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
      "SUPER SHIFT, 4, movetoworkspace, 4"
    ];
  };

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
