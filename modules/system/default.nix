{...}: {
  imports = [
    ./boot/initrd-ssh.nix
    ./boot/initrd-network.nix
    ./boot/initrd-openvpn.nix
  ];
}
