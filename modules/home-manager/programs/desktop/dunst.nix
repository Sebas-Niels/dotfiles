{ pkgs, ... }:

{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        follow = "mouse";
        width = 300;
        height = 300;
        origin = "top-right";
        offset = "10x10";
        transparency = 10;
        frame_width = 1;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        font = "monospace 10";

        # Allow sound rules
        enable_posix_regex = true;
      };

      urgency_low = {
        timeout = 5;
        sound = "${pkgs.pipewire}/bin/pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
      };

      urgency_normal = {
        timeout = 5;
        sound = "${pkgs.pipewire}/bin/pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
      };

      urgency_critical = {
        timeout = 0;
        sound = "${pkgs.pipewire}/bin/pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
      };
    };
  };
}
