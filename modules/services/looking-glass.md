# Looking Glass Module

This module provides configuration for Looking Glass, a low-latency KVMFR (KVM Frame Relay) implementation for looking glass client.

## Basic Usage

Enable Looking Glass in your NixOS configuration:

```nix
services.looking-glass = {
  enable = true;
  memSize = "128M";  # Adjust based on your resolution
  autoStart = true;  # Start automatically on boot
};
```

## Advanced Configuration

### VFIO Passthrough

To use Looking Glass with VFIO GPU passthrough, you need to specify your GPU's PCI IDs:

```nix
services.looking-glass = {
  enable = true;
  vfioIds = [
    "10de:1c03"  # NVIDIA GPU
    "10de:10f1"  # NVIDIA Audio
  ];
  extraArgs = [
    "-f" "input:grabKeyboard=yes"
    "input:grabKeyboardOnFocus=yes"
  ];
};
```

### Custom User/Group

By default, Looking Glass runs as the "ryzengrind" user in the "kvm" group. You can customize this:

```nix
services.looking-glass = {
  enable = true;
  user = "myuser";
  group = "mygroup";
};
```

### Custom Package

If you want to use a different version of Looking Glass:

```nix
services.looking-glass = {
  enable = true;
  package = pkgs.looking-glass-client-beta;  # Example
};
```

## Requirements

- A CPU with IOMMU support (Intel VT-d or AMD-Vi)
- A GPU for passthrough
- QEMU/KVM and libvirt

## Troubleshooting

1. Check if IOMMU is enabled:

   ```bash
   dmesg | grep -i -e DMAR -e IOMMU
   ```

2. Verify VFIO modules are loaded:

   ```bash
   lsmod | grep vfio
   ```

3. Check Looking Glass service status:

   ```bash
   systemctl status looking-glass
   ```

4. Check shared memory file:
   ```bash
   ls -l /dev/shm/looking-glass
   ```

## See Also

- [Looking Glass Documentation](https://looking-glass.io/docs)
- [VFIO Guide](https://nixos.wiki/wiki/VFIO)
- [NixOS KVM Guide](https://nixos.wiki/wiki/KVM)
