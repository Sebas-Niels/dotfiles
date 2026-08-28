{ self, inputs, ... }:
{
  flake.nixosModules.fastfetch =
    { pkgs, ... }:
    let
      inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) lambdaFastfetch;
    in
    {
      environment.systemPackages = [ lambdaFastfetch ];
    };

  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;

      # fastfetch's JSON parser handles \u001b, and toJSON escapes it for us
      esc = builtins.fromJSON ''"\u001b"'';
      dim = s: "${esc}[90m${s}${esc}[0m";

      width = 62;
      rule = n: lib.concatStrings (lib.genList (_: "─") n);

      box = title: {
        head = {
          type = "custom";
          format = dim (
            let
              label = " ${title} ";
              rest = width - lib.stringLength label;
              l = rest / 2;
            in
            "┌${rule l}${label}${rule (rest - l)}┐"
          );
        };
        foot = {
          type = "custom";
          format = dim "└${rule width}┘";
        };
      };

      hw = box "Hardware";
      sw = box "Software";
      up = box "Uptime / Age";
      pal = box "Palette";

      # 8 swatches * 3 columns each, centred inside the box
      swatchWidth = 24;
      swatchPad = 1 + (width - swatchWidth) / 2;

      # a real blank line; `break` gets swallowed between modules in a block
      gap = {
        type = "custom";
        format = " ";
      };
    in
    {
      packages.lambdaFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;

        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

          logo = {
            type = "builtin";
            padding.right = 4;
          };

          display = {
            separator = ": ";
            key.width = 18;
            color.keys = "green";
            size.ndigits = 2;
          };

          modules = [
            hw.head
            { type = "cpu";    key = "├─ 󰻠 CPU";    keyColor = "green"; }
            { type = "gpu";    key = "├─ 󰢮 GPU";    keyColor = "green"; }
            { type = "memory"; key = "├─ 󰍛 Memory"; keyColor = "green"; }
            { type = "disk";   key = "├─ 󰋊 Root";   folders = "/";          keyColor = "green"; }
            { type = "disk";   key = "├─ 󰋊 Games";  folders = "/mnt/games"; keyColor = "green"; }
            hw.foot
            gap

            sw.head
            { type = "os";       key = "├─ 󱄅 OS";       keyColor = "yellow"; }
            { type = "kernel";   key = "├─ 󰌽 Kernel";   keyColor = "yellow"; }
            { type = "packages"; key = "├─ 󰏖 Packages"; keyColor = "yellow"; }
            { type = "shell";    key = "├─ 󰆍 Shell";    keyColor = "yellow"; }
            gap
            { type = "wm";       key = "├─ 󰖯 WM";       keyColor = "blue"; }
            { type = "terminal"; key = "├─ 󰆍 Terminal"; keyColor = "blue"; }
            {
              type = "command";
              key = "├─ 󰢮 Driver";
              keyColor = "blue";
              text = ''
                for d in /sys/class/drm/card*/device/driver; do
                  [ -e "$d" ] && basename "$(readlink -f "$d")"
                done | sort -u | paste -sd', ' -
              '';
            }
            sw.foot
            gap

            up.head
            {
              type = "command";
              key = "├─ 󰃭 OS Age";
              keyColor = "magenta";
              text = ''
                b=$(stat -c %W /nix/store 2>/dev/null || echo 0)
                [ "''${b:-0}" -gt 0 ] || b=$(stat -c %W / 2>/dev/null || echo 0)
                echo "$(( ( $(date +%s) - b ) / 86400 )) days"
              '';
            }
            { type = "uptime"; key = "├─ 󰅐 Uptime"; keyColor = "magenta"; }
            up.foot
            gap

            pal.head
            {
              type = "colors";
              symbol = "block";
              paddingLeft = swatchPad;
            }
            pal.foot
          ];
        };
      };
    };
}