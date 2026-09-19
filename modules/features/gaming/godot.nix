{ self, inputs, ... }: {

  flake.nixosModules.godot = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      godot
    ];
  };
}