{ self, inputs, ... }: {
  flake.nixosModules.mangowm = { pkgs, lib, ... }: {
    imports = [
      inputs.mango.nixosModules.mango
      self.nixosModules.fuzzel
      self.nixosModules.swww
      self.nixosModules.mako
      self.nixosModules.waybar
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
    # pushing the new config into the running mango (started from exec-once below)
    systemd.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.apertureMango ];

    # The SDDM theme has no session picker, so make sure mango is what launches
    services.displayManager.defaultSession = lib.mkDefault "mango";

    # swaylock needs a PAM service to be able to unlock
    security.pam.services.swaylock = { };
  };

  perSystem = { pkgs, lib, self', ... }:
    let
      kitty = lib.getExe self'.packages.apertureKitty;
      zsh = lib.getExe self'.packages.apertureZsh;
      fastfetch = lib.getExe self'.packages.apertureFastfetch;

      # Floating kitty running fastfetch, sized/centred by the window rule below
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

      lock = "${lib.getExe pkgs.swaylock} -f -c 000000";

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
      packages.apertureMango = inputs.wrapper-modules.wrappers.mangowc.wrap {
        inherit pkgs;
        settings = {
          xkb_rules_layout = "us";
          numlockon = 1;
          sloppyfocus = 1;

          gappih = 5;
          gappiv = 5;
          gappoh = 5;
          gappov = 5;

          cursor_theme = "breeze_cursors";
          cursor_size = 24;

          env = [
            "XCURSOR_THEME,breeze_cursors"
            "XCURSOR_SIZE,24"
          ];

          # Master/stack tiling on every tag; tags 1-5 stay visible in waybar even when empty
          # (rules apply in order, so no_hide must come after the wildcard rule)
          tagrule = [ "id:*,layout_name:tile" ]
            ++ map (n: "id:${toString n},no_hide:1") (lib.range 1 5);

          monitorrule = [
            # centre — Dell AW3425DWM ultrawide, pinned to its high refresh mode
            "serial:BH96444,width:3440,height:1440,refresh:179.989,x:0,y:0,scale:1,primary:1"
            # right — Dell AW2724DM, pinned to its high refresh mode
            "serial:GFGYHV3,width:2560,height:1440,refresh:143.973,x:3440,y:0,scale:1"
            # bottom — Corsair Xeneon Edge, centred under the ultrawide
            "serial:578526065656,width:2560,height:720,refresh:60.266,x:440,y:1440,scale:1"
          ];

          # Keep the Xeneon's touchscreen on the Xeneon
          devicerule = [ "name:wch.cn TouchScreen,monitor:serial:578526065656" ];

          windowrule = [
            "isfloating:1,width:1620,height:910,appid:^kitty-float$"
            # Obsidian lives in a named scratchpad, toggled with SUPER+SHIFT+O, filling the monitor.
            # Sizes <= 1 are fractions of the monitor; the height leaves room for the 44px waybar
            # (1396/1440). scratchpad_*_ratio would be ignored: mango only applies it to windows
            # that are not already floating, and this rule makes Obsidian float on map.
            "isnamedscratchpad:1,width:1.0,height:0.9694,appid:^md\\.obsidian\\.Obsidian$"
          ];

          "exec-once" = [
            "${lib.getExe self'.packages.apertureSwww}"
            "${lib.getExe self'.packages.apertureWaybar}"
            "${lib.getExe self'.packages.apertureMako}"
            "${brightness}"
            # Hot-reload the config on rebuild
            "systemctl --user start mangoReloadConfig.service"
            # Start focused on the centre monitor
            "mmsg dispatch focusmon,serial:BH96444"
          ];

          bind = [
            "SUPER,d,spawn,${lib.getExe self'.packages.apertureFuzzel}"
            "SUPER+SHIFT,Return,spawn,${kitty}"
            "SUPER,Return,spawn,${floatingKitty}"
            "SUPER,q,killclient"
            "SUPER,o,toggleoverview"
            "SUPER+SHIFT,o,toggle_named_scratchpad,md\\.obsidian\\.Obsidian,none,obsidian"
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
