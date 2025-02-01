# NixOS Configuration

A NixOS configuration for managing multiple machines with a focus on reproducibility and testing.

## Structure

```
.
├── flake.nix           # Main flake configuration
├── hosts/             # Host-specific configurations
│   └── daimyo00/     # WSL development environment
├── modules/           # Reusable NixOS and home-manager modules
│   ├── nixos/        # NixOS modules
│   │   └── profiles/ # System profiles (dev, gaming, srv)
│   └── home-manager/ # Home-manager modules
├── overlays/          # Nixpkgs overlays
└── pkgs/             # Custom packages
```

## Profiles

### Development (dev.nix)
- IDE and development tools
- Language servers and formatters
- Build tools and debugging utilities

### Gaming (gaming.nix)
- Xen hypervisor configuration
- Looking Glass for GPU passthrough
- Sunshine game streaming
- Performance optimizations

### Server (srv.nix)
- Cluster management
- Monitoring stack (Prometheus + Grafana)
- Backup solutions
- Security hardening

## Usage

### WSL Development Environment

1. Install NixOS-WSL:
   ```bash
   wsl --import NixOS .\NixOS\ nixos-wsl.tar.gz --version 2
   ```

2. Build and activate:
   ```bash
   sudo nixos-rebuild switch --flake .#daimyo00
   home-manager switch --flake .#ryzengrind@daimyo00
   ```

### Testing

The repository includes comprehensive testing through GitHub Actions:
- Flake checks
- Configuration builds
- WSL testing
- Home-manager validation
- Security scanning

### Deployment

Configurations are automatically built and pushed to a binary cache when merged to main.

## Requirements

- Nix with flakes enabled
- Home-manager
- For WSL: Windows 10/11 with WSL2

## CI/CD Secrets Required

- `CACHIX_AUTH_TOKEN`: For pushing to binary cache
- `AWS_ACCESS_KEY_ID`: For S3 binary cache (optional)
- `AWS_SECRET_ACCESS_KEY`: For S3 binary cache (optional)

## Development Workflow

1. Create a new branch for changes
2. Make modifications
3. Test locally:
   ```bash
   nix flake check
   nix build .#nixosConfigurations.daimyo00.config.system.build.toplevel
   ```
4. Push changes and create PR
5. Wait for CI checks to pass
6. Merge to main

## Rollback

In case of issues after deployment:
```bash
sudo nixos-rebuild switch --flake .#daimyo00 --rollback
``` 