{ lib, pkgs, ... }:
let
  std = pkgs.stdenv;
in
{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
  ];

  networking.nameservers = lib.mkIf std.isLinux [ "8.8.8.8" ];

  virtualisation = {
    memorySize = 2048; # in MB
    diskSize = 8192; # in MB
    cores = 2; # Assign 2 CPU cores
    graphics = false;
    host = { inherit pkgs; };
    networking = {
      enable = true;
      hostName = "vm-test";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ]; # Open SSH port for access
  services.openssh.enable = true;
  services.getty.autologinUser = "root";
  users.users.root.initialPassword = "root";
}