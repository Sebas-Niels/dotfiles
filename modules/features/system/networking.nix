{ ... }: {
  flake.nixosModules.networkManager = { ... }: {
    networking.networkmanager.enable = true;
    networking = {
      interfaces.eno2.ipv4.addresses = [{
        address = "10.3.7.37";
        prefixLength = 24;
      }];
      defaultGateway = "10.3.7.1";
      nameservers = [ 
        "10.3.7.1"
        "1.1.1.1" 
        "8.8.8.8" 
      ];
      useDHCP = false;
    };
  };
}
