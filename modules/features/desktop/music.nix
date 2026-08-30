{ self, inputs, ... }:
let
  user = "nivis";
  socket = "/run/mpd/socket";
in
{
  flake.nixosModules.rmpc =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.lambdaRmpc
        pkgs.mpc
      ];

      services.mpd = {
        enable = true;
        inherit user;
        openFirewall = false;
        settings = {
          music_directory = "/home/${user}/Music/music_directory";
          bind_to_address = socket;
          auto_update = true;
          audio_output = [
            {
              type = "pulse";
              name = "PipeWire PulseAudio";
            }
          ];
        };
      };

      systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/1000";
      users.users.${user}.linger = true;
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.lambdaRmpc = inputs.wrapper-modules.lib.evalPackage [
        { inherit pkgs; }
        (
          {
            config,
            wlib,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [ wlib.modules.default ];
            package = lib.mkDefault pkgs.rmpc;
            flags."--config" = config.constructFiles.rmpcConfig.path;
            constructFiles.rmpcConfig = {
              relPath = "rmpc/config.ron";
              content = ''
                (
                    address: "${socket}",
                )
              '';
            };
          }
        )
      ];
    };
}
