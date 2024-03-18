{ inputs, ... }:
{
  imports = [
    (inputs.nixpkgs.nixosModules.virtualisation.qemu-vm)
  ];

  virtualisation.memorySize = 2048; # in MB
  virtualisation.diskSize = 8192; # in MB
  virtualisation.cores = 2; # Assign 2 CPU cores
  virtualisation.networking = {
    enable = true;
    hostName = "vm-test";
  };
  networking.firewall.allowedTCPPorts = [ 22 ]; # Open SSH port for access
  services.openssh.enable = true;
  services.getty.autologinUser = "root";
  users.users.root.initialPassword = "root";
}