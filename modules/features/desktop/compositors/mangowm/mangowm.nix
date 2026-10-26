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
      self.nixosModules.displayMenu
      self.nixosModules.lockscreen
    ];

    programs.mango = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango;
    };

    environment.etc."mango/config.conf".source = "${
      self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango
    }/config.conf";

    systemd.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango ];

    services.displayManager.defaultSession = lib.mkDefault "mango";

    xdg.portal.wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${
        lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFuzzel
      } --dmenu --prompt 'Share: '";
    };
  };

  perSystem =
    {
      pkgs,
      lib,
      self',
      inputs',
      ...
    }:
    let
      kitty = lib.getExe self'.packages.apertureKitty;
      zsh = lib.getExe self'.packages.apertureZsh;
      fastfetch = lib.getExe self'.packages.apertureFastfetch;
      themeMenu = lib.getExe self'.packages.apertureThemeMenu;
      rmpc = lib.getExe self'.packages.apertureRmpc;
      coinflip = lib.getExe self'.packages.apertureCoinflip;

      floatingKitty = pkgs.writeShellScript "mango-floating-kitty" ''
        exec ${kitty} --class=kitty-float ${zsh} -c '${fastfetch}; exec ${zsh}'
      '';

      # Flatpaks that keep running in the background after their window closes; SUPER+q kills their sandbox instead
      killFlatpaks = [ "com.adamcake.Bolt" ];

      killClient = pkgs.writeShellScript "mango-kill-client" ''
        appid=$(mmsg get focusing-client | ${lib.getExe pkgs.gnused} -nE 's/.*"appid":"([^"]*)".*/\1/p')
        case "$appid" in
          ${lib.concatStringsSep "|" killFlatpaks}) exec ${pkgs.flatpak}/bin/flatpak kill "$appid" ;;
          *) exec mmsg dispatch killclient ;;
        esac
      '';

      screenshot = pkgs.writeShellScript "mango-screenshot" ''
        dir="$HOME/Pictures/Screenshots"
        mkdir -p "$dir"
        file="$dir/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
        region=$(${lib.getExe pkgs.slurp}) || exit 1
        ${lib.getExe pkgs.grim} -g "$region" - | tee "$file" | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
      '';

      lock = lib.getExe self'.packages.apertureLock;

      tagBinds = lib.concatMap (n: [
        "SUPER,${toString n},view,${toString n},0"
        "SUPER+SHIFT,${toString n},tag,${toString n},0"
      ]) (lib.range 1 9);
    in
    {
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
        package = inputs'.mango.packages.mango;
        extraConfig = ''
          source_optional=~/.local/state/aperture-theme/current/mango.conf
        '';
        settings = {
          xkb_rules_layout = "us";
          numlock_on = 1;
          sloppy_focus = 1;

          border_px = 1;

          gap_inner_horizontal = 5;
          gap_inner_vertical = 5;
          gap_outer_horizontal = 5;
          gap_outer_vertical = 5;

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

          tag_rule = [ "id:*,layout_name:tile" ] ++ map (n: "id:${toString n},no_hide:1") (lib.range 1 5);
          default_master_factor = 0.5;

          monitor_rule = [
            # centre — Dell AW3425DWM ultrawide, pinned to its high refresh mode
            "serial:BH96444,width:3440,height:1440,refresh:179.989,x:0,y:0,scale:1,primary:1"
            # right — Dell AW2724DM, pinned to its high refresh mode
            "serial:GFGYHV3,width:2560,height:1440,refresh:143.973,x:3440,y:0,scale:1"
            # bottom — Corsair Xeneon Edge, centred under the ultrawide
            "serial:578526065656,width:2560,height:720,refresh:60.266,x:440,y:1440,scale:1"
          ];

          device_rule = [ "name:wch.cn TouchScreen,monitor:serial:578526065656" ];

          window_rule = [
            "is_floating:1,width:1620,height:910,app_id:^kitty-float$"
            "is_named_scratchpad:1,width:0.9971,height:0.9625,app_id:^md\\.obsidian\\.Obsidian$"
            "is_named_scratchpad:1,width:1620,height:910,app_id:^kitty-rmpc$"
            "is_named_scratchpad:1,width:1100,height:720,app_id:^com\\.saivert\\.pwvucontrol$"
            "is_named_scratchpad:1,width:1100,height:720,app_id:^bitwarden$"
            "tags:1,app_id:^(kitty|code)$"
            "tags:2,app_id:^librewolf$"
            "tags:3,app_id:^(signal|vesktop)$"
            "tags:4,app_id:^(steam|net\\.lutris\\.Lutris)$"
            "tags:5,app_id:^(steam_app_.*|gamescope|com\\.adamcake\\.Bolt|net-runelite-.*|RuneLite)$"
          ];

          exec_once = [
            "${lib.getExe self'.packages.apertureSwww}"
            "${lib.getExe self'.packages.apertureWaybar}"
            "${lib.getExe self'.packages.apertureMako}"
            "${themeMenu} daemon"
            "${coinflip} daemon"
            "${lib.getExe self'.packages.apertureDisplayDaemon}"
            "${lib.getExe self'.packages.apertureDisplayMenu} daemon"
            "systemctl --user start mangoReloadConfig.service"
            "mmsg dispatch focusmon,serial:BH96444"
          ];

          bind = [
            "SUPER,d,spawn,${lib.getExe self'.packages.apertureFuzzel}"
            "SUPER,t,spawn,${themeMenu} toggle"
            "SUPER,Return,spawn,${kitty}"
            "SUPER+SHIFT,Return,spawn,${floatingKitty}"
            "SUPER,q,spawn,${killClient}"
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
          ]
          ++ tagBinds;

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
