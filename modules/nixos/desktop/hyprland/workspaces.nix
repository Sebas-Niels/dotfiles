{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Workspace switching
      "SUPER, 1, workspace, 1" # Dev
      "SUPER, 2, workspace, 2" # Fun
      "SUPER, 3, workspace, 3" # Gaming

      # Move windows
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
    ];
  };

  wayland.windowManager.hyprland.settings.windowrulev2 = [
    "workspace 1, class:^(code|kitty|neovide)$"
    "workspace 2, class:^(firefox|spotify|discord)$"
    "workspace 3, class:^(steam|lutris)$"
  ];
}
