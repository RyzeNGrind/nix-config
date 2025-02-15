{...}: {
  imports = [
    ./video/nvidia.nix
    ./video/intel-gpu-tools.nix
    ./cpu/intel-microcode.nix
    ./graphics.nix
    ./ledger.nix
    ./logitech.nix
    ./usb-storage.nix
  ];
}
