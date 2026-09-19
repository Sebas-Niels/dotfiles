{ self, inputs, ... }:
{
  flake.nixosModules.fastfetch =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureFastfetch
      ];
    };

  perSystem =
    { pkgs, ... }:
    let
      # Colours (ANSI 24-bit "38;2;R;G;B").
      purple = "38;2;199;125;255";
      cyan = "38;2;80;224;224";
      blue = "38;2;1;127;223";

      # Nerd Font icons, written as JSON escapes so they survive copy-paste.
      icons = builtins.fromJSON ''
        {
          "host": "\udb80\udf22",
          "os": "\uf17c",
          "wm": "\uf2d0",
          "lm": "\udb82\udde8",
          "kernel": "\uf013",
          "bios": "\uf0ad",
          "packages": "\udb80\udfd6",
          "font": "\uf031",
          "shell": "\uf489",
          "terminal": "\uf120",
          "terminalfont": "\uf031",
          "display": "\udb80\udf79",
          "cpu": "\uf2db",
          "gpu": "\udb83\udfb2",
          "memory": "\udb80\udf5b",
          "disk": "\uf0a0",
          "uptime": "\uf017",
          "command": "\udb86\udd9f"
        }
      '';

      # Closing right-hand border of each row.
      end = "{#${purple}}│{#}";

      # Box borders, drawn as custom modules.
      box = key: {
        type = "custom";
        inherit key;
        keyColor = purple;
      };
      bottom = box "╰────────────┴───────────────────────────────────────────────────╯";

      # One row inside a box.
      row = type: key: format: {
        inherit type key format;
        keyColor = purple;
      };
    in
    {
      packages.apertureFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;

        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

          logo = {
            source = "PrismLinux";
            color."1" = blue;
            padding = {
              top = 4;
              left = 5;
              right = 5;
            };
          };

          display = {
            bar = {
              char.total = "─";
              color = {
                border = cyan;
                total = cyan;
              };
              width = 10;
            };
            percent = {
              type = 3;
              ndigits = 2;
            };
            key.width = 16;
            separator = "";
            color = {
              title = purple;
              output = cyan;
            };
          };

          modules = [
            "break"

            # System
            (box "╭─System─────┬───────────────────────────────────────────────────╮")
            (row "host" "├╴${icons.host} PC       │" "{name<16}({version<6})                          ${end}")
            (row "os" "├╴${icons.os} OS       │" "{name<6}{version<6}({codename<5}) {arch<6}                        ${end}")
            (row "wm" "├╴${icons.wm} WM       │" "{pretty-name<5}{version<6}({protocol-name<7})                              ${end}")
            (row "lm" "├╴${icons.lm} LM       │" "{pretty-name<20}{version<30}${end}")
            (row "kernel" "├╴${icons.kernel} Kernel   │" "{sysname<6}{release<44}${end}")
            (row "bios" "├╴${icons.bios} BIOS     │" "{version<5}({release<4})                                       ${end}")
            (row "packages" "├╴${icons.packages} Packages │" "{nix-system<5}(nix-system), {nix-user<4}(nix-user)                 ${end}")
            (row "font" "├╴${icons.font} Font     │" "{combined<50}${end}")
            bottom

            # Terminal
            (box "╭─Terminal───┬───────────────────────────────────────────────────╮")
            (row "shell" "├╴${icons.shell} Shell    │" "{pretty-name<4}{version<46}${end}")
            (row "terminal" "├╴${icons.terminal} Terminal │" "{pretty-name<6}{version<44}${end}")
            (row "terminalfont" "├╴${icons.terminalfont} Font     │" "{combined<50}${end}")
            bottom

            # Hardware
            (box "╭─Hardware───┬───────────────────────────────────────────────────╮")
            (row "display" "├╴${icons.display} Display  │" "{width<4}×{height<4}, {refresh-rate>3}Hz [{type<8}]                       ${end}")
            (row "cpu" "├╴${icons.cpu} CPU      │" "{name<28}[{cores-physical<2} cores]            ${end}")
            (row "gpu" "├╴${icons.gpu} GPU      │" "{vendor<7}{name<23}[{type<8}]          ${end}")
            (row "memory" "├╴${icons.memory} RAM      │" "{percentage-bar} {used<9}/ {total<10}({percentage<6})      ${end}")
            (
              row "disk" "├╴${icons.disk} Disk     │" "{size-percentage-bar} {size-used>10} / {size-total<9}({size-percentage>6})     ${end}"
              // {
                showExternal = true;
                showHidden = true;
                showSubvolumes = false;
                showReadOnly = false;
                showUnknown = true;
              }
            )
            bottom

            # Uptime
            (
              box "╭─Uptime─────┬"
              // {
                format = "{#90}◆ {#97}◆ {#94}◆ {#95}◆ {#96}◆ {#93}◆ {#92}◆ {#91}◆ {#${purple}}──────────────────────────────────╮{#}";
              }
            )
            (row "uptime" "├╴${icons.uptime} Uptime   │" "{formatted<50}${end}")
            {
              type = "command";
              key = "├╴${icons.command} OS Age   │";
              keyColor = purple;
              text = ''birth_install=$(stat -c %W /); current=$(date +%s); days_difference=$(( (current - birth_install) / 86400 )); printf '%-50s\033[${purple}m│\033[0m' "$days_difference days"'';
            }
            bottom
          ];
        };
      };
    };
}