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

          # Master/stack tiling on every tag
          tagrule = [ "id:*,layout_name:tile" ];

          monitorrule = [
            # centre — Dell AW2724DM, pinned to its high refresh mode
            "serial:GFGYHV3,width:2560,height:1440,refresh:143.973,x:1920,y:0,scale:1,primary:1"
            # left — Samsung SyncMaster
            "serial:H9XB408702,width:1920,height:1200,refresh:59.950,x:0,y:120,scale:1"
            # right — Samsung SyncMaster
            "serial:H9XZ111348,width:1920,height:1200,refresh:59.950,x:4480,y:120,scale:1"
            # bottom — Corsair Xeneon Edge, flush under the Dell
            "serial:578526065656,width:2560,height:720,refresh:60.266,x:1920,y:1440,scale:1"
          ];

          # Keep the Xeneon's touchscreen on the Xeneon
          devicerule = [ "name:wch.cn TouchScreen,monitor:serial:578526065656" ];

          windowrule = [
            "isfloating:1,width:1620,height:910,appid:^kitty-float$"
          ];

          "exec-once" = [
            "${lib.getExe self'.packages.apertureSwww}"
            "${lib.getExe self'.packages.apertureWaybar}"
            "${lib.getExe self'.packages.apertureMako}"
            # Start focused on the centre monitor
            "mmsg dispatch focusmon,serial:GFGYHV3"
          ];

          bind = [
            "SUPER,d,spawn,${lib.getExe self'.packages.apertureFuzzel}"
            "SUPER+SHIFT,Return,spawn,${kitty}"
            "SUPER,Return,spawn,${floatingKitty}"
            "SUPER,q,killclient"
            "SUPER,o,toggleoverview"
            "NONE,Print,spawn,${screenshot}"
            "CTRL+ALT,l,spawn,${lock}"
            "SUPER,r,reload_config"
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
