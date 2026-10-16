{ self, inputs, ... }: {
  flake.nixosModules.mangowm = { pkgs, lib, ... }: {
    imports = [
      inputs.mango.nixosModules.mango
      self.nixosModules.fuzzel
      self.nixosModules.swww
      self.nixosModules.mako
      self.nixosModules.waybar
      self.nixosModules.themeMenu
      self.nixosModules.coinflip
      self.nixosModules.lockscreen
    ];

    programs.mango = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango;
    };

    # mango runs with -c pointing at an immutable store path, so reload_config would only ever
    # re-read the old config; expose the current one at a stable path for SUPER+R to load
    environment.etc."mango/config.conf".source =
      "${self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango}/config.conf";

    # Ships mangoReloadConfig.service, which nixos-rebuild reloads whenever the config changes,
    # pushing the new config into the running mango (started from exec_once below)
    systemd.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango ];

    # The SDDM theme has no session picker, so make sure mango is what launches
    services.displayManager.defaultSession = lib.mkDefault "mango";

    # With several monitors the wlr portal asks which one to share, by default through whichever
    # of wofi/rofi/bemenu/fuzzel it finds on PATH. Its user service's PATH has none of them, so
    # every screenshare failed; point it at fuzzel directly
    xdg.portal.wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${
        lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFuzzel
      } --dmenu --prompt 'Share: '";
    };
  };

  perSystem = { pkgs, lib, self', inputs', ... }:
    let
      kitty = lib.getExe self'.packages.apertureKitty;
      zsh = lib.getExe self'.packages.apertureZsh;
      fastfetch = lib.getExe self'.packages.apertureFastfetch;
      themeMenu = lib.getExe self'.packages.apertureThemeMenu;
      rmpc = lib.getExe self'.packages.apertureRmpc;
      coinflip = lib.getExe self'.packages.apertureCoinflip;

      # Floating kitty running fastfetch, sized by the window rule below
      floatingKitty = pkgs.writeShellScript "mango-floating-kitty" ''
        exec ${kitty} --class=kitty-float ${zsh} -c '${fastfetch}; exec ${zsh}'
      '';

      # Region screenshot, copied to the clipboard and saved like niri did
      screenshot = pkgs.writeShellScript "mango-screenshot" ''
        dir="$HOME/Pictures/Screenshots"
        mkdir -p "$dir"
        file="$dir/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
        region=$(${lib.getExe pkgs.slurp}) || exit 1
        ${lib.getExe pkgs.grim} -g "$region" - | tee "$file" | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
      '';

      lock = lib.getExe self'.packages.apertureLock;

      # Set every DDC/CI-capable monitor to 30% brightness at login
      brightness = pkgs.writeShellScript "mango-brightness" ''
        ddcutil=${lib.getExe pkgs.ddcutil}
        for display in $($ddcutil detect --terse | ${lib.getExe pkgs.gawk} '/^Display/ {print $2}'); do
          $ddcutil --display "$display" setvcp 10 30
        done
      '';

      # SUPER+N views tag N, SUPER+SHIFT+N moves the focused window there
      tagBinds = lib.concatMap (n: [
        "SUPER,${toString n},view,${toString n},0"
        "SUPER+SHIFT,${toString n},tag,${toString n},0"
      ]) (lib.range 1 9);
    in
    {
      # Window border colours, rendered once per theme by the theme menu (see theme-menu.nix)
      apertureTheme.targets."mango.conf" = t: ''
        border_color=0x${t.bare t.c.overlay}ff
        focus_color=0x${t.bare t.c.accent}ff
        urgent_color=0x${t.bare t.c.red}ff
        scratchpad_color=0x${t.bare t.c.accent2}ff
        maximized_screen_color=0x${t.bare t.c.accent2}ff
        root_color=0x${t.bare t.c.mantle}ff
      '';

      packages.apertureMango = inputs.wrapper-modules.wrappers.mangowc.wrap {
        inherit pkgs;
        # mango from its own flake rather than nixpkgs: newer releases give a window its tiled
        # size before it first draws, so it slides in at that size instead of at its own saved
        # size (Dolphin's is the whole screen) and then snapping to its tile mid-animation
        package = inputs'.mango.packages.mango;
        # Last, so the theme's colours win; optional, so mango starts before a theme is picked
        extraConfig = ''
          source_optional=~/.local/state/aperture-theme/current/mango.conf
        '';
        settings = {
          xkb_rules_layout = "us";
          numlock_on = 1;
          sloppy_focus = 1;

          gap_inner_horizontal = 5;
          gap_inner_vertical = 5;
          gap_outer_horizontal = 5;
          gap_outer_vertical = 5;

          # Blur behind translucent windows (kitty); kitty's own background_blur only works on
          # macOS and KDE. The optimized blur is drawn once per monitor from the wallpaper.
          blur = 1;
          blur_layer = 0;
          blur_optimized = 1;
          blur_params_num_passes = 3;
          blur_params_radius = 8;

          cursor_theme = "breeze_cursors";
          cursor_size = 24;

          env = [
            "XCURSOR_THEME,breeze_cursors"
            "XCURSOR_SIZE,24"
          ];

          # Master/stack tiling on every tag; tags 1-5 stay visible in waybar even when empty
          # (rules apply in order, so no_hide must come after the wildcard rule)
          tag_rule = [ "id:*,layout_name:tile" ]
            ++ map (n: "id:${toString n},no_hide:1") (lib.range 1 5);
          # The master and the stack each get half the width (the stack's windows share its height)
          default_master_factor = 0.5;

          monitor_rule = [
            # centre — Dell AW3425DWM ultrawide, pinned to its high refresh mode
            "serial:BH96444,width:3440,height:1440,refresh:179.989,x:0,y:0,scale:1,primary:1"
            # right — Dell AW2724DM, pinned to its high refresh mode
            "serial:GFGYHV3,width:2560,height:1440,refresh:143.973,x:3440,y:0,scale:1"
            # bottom — Corsair Xeneon Edge, centred under the ultrawide
            "serial:578526065656,width:2560,height:720,refresh:60.266,x:440,y:1440,scale:1"
          ];

          # Keep the Xeneon's touchscreen on the Xeneon
          device_rule = [ "name:wch.cn TouchScreen,monitor:serial:578526065656" ];

          window_rule = [
            "is_floating:1,width:1620,height:910,app_id:^kitty-float$"
            # Obsidian lives in a named scratchpad, toggled with SUPER+SHIFT+O, sized like a
            # maximized window. Sizes <= 1 are fractions of the monitor: on the ultrawide that is
            # 3430x1386, the 3440x1396 area below the 44px waybar minus the 5px outer gaps.
            # It can't be any bigger: mango shrinks floating windows within a gap of the work area
            # to 90% of it. scratchpad_*_ratio would be ignored: mango only applies it to windows
            # that are not already floating, and this rule makes Obsidian float on map.
            "is_named_scratchpad:1,width:0.9971,height:0.9625,app_id:^md\\.obsidian\\.Obsidian$"
            # rmpc runs in kitty in a named scratchpad, toggled with SUPER+SHIFT+M
            "is_named_scratchpad:1,width:1620,height:910,app_id:^kitty-rmpc$"
            # pwvucontrol, toggled by clicking the volume in waybar
            "is_named_scratchpad:1,width:1100,height:720,app_id:^com\\.saivert\\.pwvucontrol$"
            # Bitwarden in a named scratchpad, toggled with SUPER+SHIFT+B
            "is_named_scratchpad:1,width:1100,height:720,app_id:^bitwarden$"
            # kitty and VS Code always open on tag 1, LibreWolf on tag 2, messaging on tag 3, game
            # launchers on tag 4, and games on tag 5. The kitty match is exact so the floating and
            # scratchpad kitties are left alone. Steam games are steam_app_<id>, and anything run
            # through gamescope is gamescope
            "tags:1,app_id:^(kitty|code)$"
            "tags:2,app_id:^librewolf$"
            "tags:3,app_id:^(signal|vesktop)$"
            "tags:4,app_id:^(steam|net\\.lutris\\.Lutris)$"
            "tags:5,app_id:^(steam_app_.*|gamescope)$"
          ];

          exec_once = [
            "${lib.getExe self'.packages.apertureSwww}"
            "${lib.getExe self'.packages.apertureWaybar}"
            "${lib.getExe self'.packages.apertureMako}"
            # Start the theme menu hidden so SUPER+T opens it instantly
            "${themeMenu} daemon"
            # The coin down the right of the Xeneon
            "${coinflip} daemon"
            "${brightness}"
            # Hot-reload the config on rebuild
            "systemctl --user start mangoReloadConfig.service"
            # Start focused on the centre monitor
            "mmsg dispatch focusmon,serial:BH96444"
          ];

          bind = [
            "SUPER,d,spawn,${lib.getExe self'.packages.apertureFuzzel}"
            "SUPER,t,spawn,${themeMenu} toggle"
            "SUPER,Return,spawn,${kitty}"
            "SUPER+SHIFT,Return,spawn,${floatingKitty}"
            "SUPER,q,killclient"
            "SUPER,o,toggleoverview"
            "SUPER+SHIFT,o,toggle_named_scratchpad,md\\.obsidian\\.Obsidian,none,obsidian"
            "SUPER+SHIFT,m,toggle_named_scratchpad,kitty-rmpc,none,${kitty} --class=kitty-rmpc ${rmpc}"
            "SUPER+SHIFT,b,toggle_named_scratchpad,bitwarden,none,bitwarden"
            "NONE,Print,spawn,${screenshot}"
            "CTRL+ALT,l,spawn,${lock}"
            "SUPER,r,load_config_file,/etc/mango/config.conf"
            "SUPER+SHIFT,e,quit"

            "SUPER+CTRL,f,togglefullscreen"
            "SUPER+SHIFT,f,togglemaximizescreen"
            "SUPER,space,togglefloating"

            # grow/shrink the master area, and add/remove master windows
            "SUPER,equal,setmfact,+0.05"
            "SUPER,minus,setmfact,-0.05"
            "SUPER,comma,incnmaster,+1"
            "SUPER,period,incnmaster,-1"

            # focus the neighbouring window in each direction
            "SUPER,h,focusdir,left"
            "SUPER,l,focusdir,right"
            "SUPER,k,focusdir,up"
            "SUPER,j,focusdir,down"
            "SUPER,Left,focusdir,left"
            "SUPER,Right,focusdir,right"

            # swap the focused window with its neighbour
            "SUPER+CTRL,h,exchange_client,left"
            "SUPER+CTRL,l,exchange_client,right"
            "SUPER+CTRL,Left,exchange_client,left"
            "SUPER+CTRL,Right,exchange_client,right"
          ] ++ tagBinds;

          mousebind = [
            "SUPER,btn_left,moveresize,curmove"
            "SUPER,btn_right,moveresize,curresize"
          ];

          # mouse wheel scrolling
          axisbind = [
            "SUPER,UP,focusdir,left"
            "SUPER,DOWN,focusdir,right"
            "SUPER,LEFT,focusdir,left"
            "SUPER,RIGHT,focusdir,right"
          ];
        };
      };
    };
}
