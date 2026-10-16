{ ... }: {
  flake.nixosModules.sshAgent = { ... }: {
    services.gnome.gnome-keyring.enable = true;

    environment.extraInit = ''
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
    '';
  };
}
