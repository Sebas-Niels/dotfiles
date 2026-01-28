{ ... }:

{
    wayland.windowManager.hyprland.settings = {


      #############################
      # MOD KEY
      #############################

      "$mod" = "SUPER";

      #############################
      # KEYBINDS
      #############################

      bind = [
        "$mod, Return, exec, kitty"
        "$mod SHIFT, Return, exec, foot"
        "$mod, D, exec, rofi -show drun"

        "CTRL ALT, L, exec, hyprlock"

        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, M, exit"

        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"


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
}
