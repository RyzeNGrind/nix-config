# NixOS Hyperconverged Infrastructure Configuration

A comprehensive NixOS configuration for managing hyperconverged infrastructure, supporting multiple formats and deployment targets including WSL, VMs, containers, and bare metal systems.

## Features

- 🖥️ Multi-platform support (x86_64-linux, aarch64-linux, etc.)
- 🐋 Container and VM image generation
- 💾 Installation media creation
- 🏠 Home Manager configuration
- 🔧 Development shell with essential tools
- ✅ Automated testing for all formats

## Prerequisites

- Nix package manager with flakes enabled
- Git
- WSL2 (for Windows users)

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/RyzeNGrind/nix-config.git
cd nix-config
```

2. Enter the development shell:
```bash
# These commands are equivalent:
nix develop
nix develop .#default
```

3. Build and activate a configuration:
```bash
# For WSL
sudo nixos-rebuild switch --flake .#daimyo00

# For home-manager
home-manager switch --flake .#ryzengrind@daimyo00
```

## Available Configurations

### Default Package

The default package (`nix build` or `nix develop`) builds the `all-formats` package, which includes:
- All format outputs (Docker, ISO, etc.)
- Testing utilities
- Format validation tools

### NixOS Configurations

- `daimyo00`: WSL configuration with development tools
- `vm-test`: Example VM configuration
- `container-test`: Example container configuration

### Format-Specific Configurations

- `docker-test`: Docker container image
- `iso-test`: Installation ISO
- `kexec-test`: Kexec bundle
- `sd-test`: SD card image for Raspberry Pi (aarch64)

## Building Different Formats

### Docker Image
```bash
nix build .#docker-test
```

### Installation ISO
```bash
nix build .#install-iso-test
```

### Kexec Bundle
```bash
nix build .#kexec-test
nix build .#kexec-bundle-test
```

### SD Card Image (aarch64)
```bash
nix build .#sd-aarch64-test
```

### Build All Formats
```bash
nix build .#all-formats
```

## Testing

Run all format tests:
```bash
nix build .#checks.x86_64-linux.format-tests
```

Individual format tests:
```bash
# Docker test
nix build .#checks.x86_64-linux.format-tests.testDocker

# ISO test
nix build .#checks.x86_64-linux.format-tests.testISO

# Kexec test
nix build .#checks.x86_64-linux.format-tests.testKexec

# SD image test (aarch64 only)
nix build .#checks.aarch64-linux.format-tests.testSDImage
```

## Troubleshooting

### Common Issues

1. **Duplicate Format Definitions**
   If you see errors about duplicate format definitions (e.g., "The option `formats.docker' is defined multiple times"), check your configuration for multiple definitions of the same format. Use `lib.mkForce` or `lib.mkDefault` to set priorities:
   ```nix
   formats.docker = lib.mkForce {
     # Your configuration here
   };
   ```

2. **Duplicate Package Lists**
   If you get errors about duplicate `environment.systemPackages`, merge the package lists or use `lib.mkDefault`:
   ```nix
   environment.systemPackages = lib.mkDefault (with pkgs; [
     # Your packages here
   ]);
   ```

3. **Development Shell Issues**
   If `nix develop` fails, try:
   ```bash
   # Override nixpkgs input
   nix develop --override-input nixpkgs git+https://github.com/NixOS/nixpkgs.git

   # Get detailed error traces
   nix develop --show-trace
   ```

### Getting Help

If you encounter issues:
1. Check the error messages carefully
2. Use `--show-trace` for detailed error information
3. Review your configuration for duplicate definitions
4. Make sure all required inputs are available
5. Check that your flake.lock is up to date

## Directory Structure

```
.
├── flake.nix              # Main flake configuration
├── flake.lock            # Flake lockfile
├── hosts/                # Host-specific configurations
│   └── daimyo00/        # WSL configuration
├── home-manager/        # Home Manager configuration
├── modules/             # Reusable NixOS and Home Manager modules
│   ├── nixos/          # NixOS modules
│   ├── home-manager/   # Home Manager modules
│   └── nixos-wsl/      # WSL-specific modules
├── overlays/           # Nixpkgs overlays
├── pkgs/              # Custom packages
└── tests/             # Test configurations
```

## Customization

### Adding a New Host

1. Create a new directory under `hosts/`:
```bash
mkdir -p hosts/my-host
```

2. Create a `configuration.nix` file:
```nix
# hosts/my-host/configuration.nix
{ config, lib, pkgs, ... }: {
  # Your host-specific configuration here
}
```

3. Add the configuration to `flake.nix`:
```nix
nixosConfigurations = {
  my-host = mkSystem "my-host" "x86_64-linux" [
    ./hosts/my-host/configuration.nix
  ];
};
```

### Adding a New Format

1. Add the format configuration to `modules/nixos/formats.nix`
2. Add the format to `baseFormatConfig` in `flake.nix`
3. Create a new configuration in `nixosConfigurations`
4. Add build and test targets in `packages` and `checks`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your fork
5. Create a Pull Request

## License

MIT - See [LICENSE](LICENSE) for details. 