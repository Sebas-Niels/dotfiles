{ ... }: {
  flake.nixosModules.sshAgent = { ... }: {
    # gnome-keyring is the SSH agent (gcr-ssh-agent) and secret store, unlocked with the login
    # password through SDDM, so key passphrases are remembered. niri's module enables it too.
    services.gnome.gnome-keyring.enable = true;

    # gcr-ssh-agent only puts SSH_AUTH_SOCK in systemd's environment, which a compositor started
    # straight from SDDM (like mango) never imports
    environment.extraInit = ''
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
    '';
  };
}
