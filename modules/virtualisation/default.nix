{...}: {
  imports = [
    ./looking-glass.nix
    ./libvirtd.nix
    ./docker.nix
    ./podman
    ./qemu-vm.nix
    ./spice-usb-redirection.nix
  ];
}
