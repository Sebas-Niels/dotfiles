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

      # ── raw ANSI, since fastfetch's JSON parser eats \u001b fine ──
      esc = builtins.fromJSON ''"\u001b"'';
      dim = s: "${esc}[90m${s}${esc}[0m";

      # ── box helpers ──────────────────────────────────────────────
      width = 62;
      rule = n: lib.concatStrings (lib.genList (_: "─") n);

      box = title: rec {
        label = " ${title} ";
        head = {
          type = "custom";
          format = dim (
            let
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

      br = { type = "break"; };
    in
    {
      packages.lambdaFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;

        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

          logo.type = "none";

          display = {
            separator = ": ";
            keyWidth = 6;
            color = {
              keys = "green";
              output = "white";
            };
            size.ndigits = 2;
          };

          modules = [
            hw.head
            { type = "cpu";    key = "├─  "; keyColor = "green"; }
            { type = "gpu";    key = "├─ 󰢮 "; keyColor = "green"; }
            { type = "memory"; key = "├─ 󰍛 "; keyColor = "green"; }
            { type = "disk";   key = "├─ 󰋊 "; folders = "/";     keyColor = "green"; }
            { type = "disk";   key = "└─ 󰋊 "; folders = "/home"; keyColor = "green"; }
            hw.foot
            br

            sw.head
            { type = "os";       key = "├─  OS"; keyColor = "yellow"; }
            { type = "kernel";   key = "├─  ";   keyColor = "yellow"; }
            { type = "packages"; key = "├─ 󰏖 ";   keyColor = "yellow"; }
            { type = "shell";    key = "└─  ";   keyColor = "yellow"; }
            br
            { type = "lm"; key = "├─ 󰧨 "; keyColor = "blue"; }
            { type = "wm"; key = "├─  "; keyColor = "blue"; }
            {
              type = "command";
              key = "└─ 󰢮 ";
              keyColor = "blue";
              text = ''basename "$(readlink -f /sys/class/drm/card0/device/driver)" 2>/dev/null || echo unknown'';
            }
            sw.foot
            br

            up.head
            {
              type = "command";
              key = "OS Age";
              keyColor = "magenta";
              text = ''echo "$(( ( $(date +%s) - $(stat -c %W /) ) / 86400 )) days"'';
            }
            { type = "uptime"; key = "Uptime"; keyColor = "magenta"; }
            up.foot
          ];
        };
      };
    };
}